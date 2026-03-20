import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ClipboardStore
    @State private var searchText = ""
    @State private var eventMonitor: Any?

    private var filteredItems: [ClipboardItem] {
        store.items(matching: searchText)
    }

    private var pinnedItems: [ClipboardItem] {
        filteredItems.filter(\.isPinned)
    }

    private var recentItems: [ClipboardItem] {
        filteredItems.filter { !$0.isPinned }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchBar
            Divider()
            bodyContent
            Divider()
            footer
        }
        .frame(width: 440, height: 560)
        .background(.ultraThinMaterial)
        .onAppear {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) {
                    if let characters = event.charactersIgnoringModifiers,
                       let num = Int(characters),
                       (1...9).contains(num) {
                        
                        let indexToCopy = num - 1
                        let totalCount = pinnedItems.count + recentItems.count
                        
                        if indexToCopy < totalCount {
                            let targetItem: ClipboardItem
                            if indexToCopy < pinnedItems.count {
                                targetItem = pinnedItems[indexToCopy]
                            } else {
                                targetItem = recentItems[indexToCopy - pinnedItems.count]
                            }
                            store.copy(targetItem)
                            
                            // Optional: Close popover after copy (MenuBarExtra automatically handles this if desired, or we can leave it)
                            return nil // consume event
                        }
                    }
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PocketPaste")
                    .font(.title2.weight(.semibold))

                Text(store.isMonitoringEnabled ? "Watching your clipboard" : "Clipboard capture paused")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(filteredItems.count)")
                .font(.headline.monospacedDigit())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                .foregroundStyle(Color.accentColor)
        }
        .padding(16)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search clipboard history", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var bodyContent: some View {
        if filteredItems.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !pinnedItems.isEmpty {
                        sectionLabel("Pinned")

                        ForEach(Array(pinnedItems.enumerated()), id: \.element.id) { index, item in
                            ClipboardRowView(
                                item: item,
                                shortcutIndex: index,
                                onCopy: { store.copy(item) },
                                onTogglePin: { store.togglePinned(item) },
                                onDelete: { store.delete(item) }
                            )
                        }
                    }

                    if !recentItems.isEmpty {
                        sectionLabel(pinnedItems.isEmpty ? "Recent" : "Recent Copies")

                        ForEach(Array(recentItems.enumerated()), id: \.element.id) { index, item in
                            ClipboardRowView(
                                item: item,
                                shortcutIndex: pinnedItems.count + index,
                                onCopy: { store.copy(item) },
                                onTogglePin: { store.togglePinned(item) },
                                onDelete: { store.delete(item) }
                            )
                        }
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.visible)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image("CustomLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            Text(searchText.isEmpty ? "Your clipboard history will appear here." : "No clipboard matches for that search.")
                .font(.headline)

            Text(searchText.isEmpty ? "Copy text or images anywhere on your Mac and PocketPaste will keep a searchable history." : "Try a different keyword or clear the search field.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button(store.isMonitoringEnabled ? "Pause" : "Resume") {
                store.toggleMonitoring()
            }

            Button("Clear Unpinned") {
                store.clearUnpinnedHistory()
            }
            .disabled(store.items.allSatisfy(\.isPinned))

            Spacer()

            if let statusMessage = store.statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(16)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}
