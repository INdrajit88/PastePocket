import AppKit
import Combine
import CryptoKit
import Foundation

@MainActor
final class ClipboardStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem] = []
    @Published private(set) var isMonitoringEnabled = true
    @Published private(set) var statusMessage: String?

    private let pasteboard = NSPasteboard.general
    private let maxHistoryCount = 150
    private let persistenceURL: URL

    private var lastObservedChangeCount: Int
    private var monitorTimer: Timer?
    private var pendingAppWriteSignature: String?
    private var statusResetTask: Task<Void, Never>?

    private struct CapturedImagePayload {
        let data: Data
        let width: Int?
        let height: Int?
        let format: String
    }

    init() {
        persistenceURL = Self.makePersistenceURL()
        lastObservedChangeCount = NSPasteboard.general.changeCount

        loadHistory()
        startMonitoring()
        captureIfNeeded(force: true)
    }

    var sortedItems: [ClipboardItem] {
        items.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            return lhs.lastCopiedAt > rhs.lastCopiedAt
        }
    }

    func items(matching query: String) -> [ClipboardItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return sortedItems
        }

        let normalizedQuery = trimmedQuery.lowercased()
        return sortedItems.filter { item in
            item.searchText.lowercased().contains(normalizedQuery)
        }
    }

    func copy(_ item: ClipboardItem) {
        pasteboard.clearContents()

        switch item.kind {
        case .text, .url:
            pasteboard.setString(item.content, forType: .string)
        case .image:
            guard
                let imageData = item.imageData,
                let image = NSImage(data: imageData),
                pasteboard.writeObjects([image])
            else {
                showStatus("Could not restore that image")
                return
            }
        }

        pendingAppWriteSignature = Self.signature(for: item)

        updateItem(id: item.id) { existing in
            existing.lastCopiedAt = Date()
        }

        saveHistory()
        showStatus("Copied & Pasting...")

        autoPaste()
    }

    private func autoPaste() {
        // Hide PasteMac so previous app regains focus
        NSApp.hide(nil)
        
        // Wait slightly for the window to actually hide and focus to switch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let vKeyCode: CGKeyCode = 0x09 // 'v' key
            
            guard let source = CGEventSource(stateID: .hidSystemState) else { return }
            
            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else { return }
            
            keyDown.flags = .maskCommand
            keyUp.flags = .maskCommand
            
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }
    }

    func togglePinned(_ item: ClipboardItem) {
        updateItem(id: item.id) { existing in
            existing.isPinned.toggle()
        }

        saveHistory()
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearUnpinnedHistory() {
        items.removeAll { !$0.isPinned }
        saveHistory()
        showStatus("Cleared recent history")
    }

    func toggleMonitoring() {
        isMonitoringEnabled.toggle()

        if isMonitoringEnabled {
            lastObservedChangeCount = pasteboard.changeCount
            captureIfNeeded(force: true)
            showStatus("Clipboard monitoring resumed")
        } else {
            showStatus("Clipboard monitoring paused")
        }
    }

    private func startMonitoring() {
        let timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.captureIfNeeded()
            }
        }

        timer.tolerance = 0.2
        monitorTimer = timer
    }

    private func captureIfNeeded(force: Bool = false) {
        let currentChangeCount = pasteboard.changeCount
        guard force || currentChangeCount != lastObservedChangeCount else {
            return
        }

        defer {
            lastObservedChangeCount = currentChangeCount
        }

        guard isMonitoringEnabled else {
            return
        }

        if let imageItem = capturedImageItem() {
            storeCapturedItem(imageItem)
            return
        }

        guard let rawString = pasteboard.string(forType: .string) else {
            return
        }

        let normalized = Self.normalize(rawString)
        guard !normalized.isEmpty else {
            return
        }

        let now = Date()
        let item = ClipboardItem(
            content: normalized,
            kind: Self.kind(for: normalized),
            createdAt: now,
            lastCopiedAt: now
        )

        storeCapturedItem(item)
    }

    private func trimHistory() {
        let pinnedItems = items.filter(\.isPinned)
        let unpinnedItems = items
            .filter { !$0.isPinned }
            .sorted { $0.lastCopiedAt > $1.lastCopiedAt }

        let availableSlots = max(maxHistoryCount - pinnedItems.count, 0)
        items = pinnedItems + Array(unpinnedItems.prefix(availableSlots))
    }

    private func updateItem(id: UUID, update: (inout ClipboardItem) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        update(&items[index])
    }

    private func storeCapturedItem(_ item: ClipboardItem) {
        let signature = Self.signature(for: item)
        if pendingAppWriteSignature == signature {
            pendingAppWriteSignature = nil
            return
        }

        let now = Date()
        if let existingIndex = items.firstIndex(where: { Self.areEquivalent($0, item) }) {
            items[existingIndex].lastCopiedAt = now
            items[existingIndex].content = item.content
            items[existingIndex].kind = item.kind
            items[existingIndex].imageData = item.imageData
            items[existingIndex].imageWidth = item.imageWidth
            items[existingIndex].imageHeight = item.imageHeight
            items[existingIndex].imageFormat = item.imageFormat
        } else {
            items.append(item)
        }

        trimHistory()
        saveHistory()
    }

    private func capturedImageItem() -> ClipboardItem? {
        guard let payload = Self.imagePayload(from: pasteboard) else {
            return nil
        }

        let now = Date()
        return ClipboardItem(
            content: Self.imageSearchText(
                format: payload.format,
                width: payload.width,
                height: payload.height
            ),
            kind: .image,
            createdAt: now,
            lastCopiedAt: now,
            imageData: payload.data,
            imageWidth: payload.width,
            imageHeight: payload.height,
            imageFormat: payload.format
        )
    }

    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: persistenceURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: persistenceURL)
            items = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            showStatus("Could not load previous history")
        }
    }

    private func saveHistory() {
        do {
            let directoryURL = persistenceURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )

            let data = try JSONEncoder().encode(items)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            showStatus("Could not save clipboard history")
        }
    }

    private func showStatus(_ message: String) {
        statusResetTask?.cancel()
        statusMessage = message

        statusResetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                self?.clearStatusMessage()
            }
        }
    }

    private func clearStatusMessage() {
        statusMessage = nil
    }

    private static func makePersistenceURL() -> URL {
        let appSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        return appSupportURL
            .appendingPathComponent("PasteMac", isDirectory: true)
            .appendingPathComponent("history.json", isDirectory: false)
    }

    private static func kind(for content: String) -> ClipboardKind {
        if let url = URL(string: content), url.scheme != nil {
            return .url
        }

        return .text
    }

    private static func imagePayload(from pasteboard: NSPasteboard) -> CapturedImagePayload? {
        guard let image = NSImage(pasteboard: pasteboard) else {
            return nil
        }

        guard let tiffData = image.tiffRepresentation else {
            return nil
        }

        guard let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        let pngData = bitmap.representation(using: .png, properties: [:]) ?? tiffData
        let width = bitmap.pixelsWide > 0 ? bitmap.pixelsWide : nil
        let height = bitmap.pixelsHigh > 0 ? bitmap.pixelsHigh : nil
        let format = bitmap.representation(using: .png, properties: [:]) != nil ? "PNG" : "TIFF"

        return CapturedImagePayload(
            data: pngData,
            width: width,
            height: height,
            format: format
        )
    }

    private static func normalize(_ string: String) -> String {
        string.replacingOccurrences(of: "\r\n", with: "\n")
    }

    private static func signature(for item: ClipboardItem) -> String {
        switch item.kind {
        case .text, .url:
            return "\(item.kind.rawValue):\(item.content.count):\(item.content)"
        case .image:
            guard let imageData = item.imageData else {
                return "image:missing"
            }

            let digest = SHA256.hash(data: imageData)
            let hash = digest.compactMap { String(format: "%02x", $0) }.joined()
            return "image:\(hash)"
        }
    }

    private static func areEquivalent(_ lhs: ClipboardItem, _ rhs: ClipboardItem) -> Bool {
        guard lhs.kind == rhs.kind else {
            return false
        }

        switch lhs.kind {
        case .text, .url:
            return lhs.content == rhs.content
        case .image:
            return lhs.imageData == rhs.imageData
        }
    }

    private static func imageSearchText(format: String, width: Int?, height: Int?) -> String {
        let dimensions: String?
        if let width, let height {
            dimensions = "\(width)x\(height)"
        } else {
            dimensions = nil
        }

        return [
            "image",
            format.lowercased(),
            dimensions
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
}
