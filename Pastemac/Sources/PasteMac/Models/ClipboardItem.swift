import Foundation

enum ClipboardKind: String, Codable {
    case text
    case url
    case image
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var kind: ClipboardKind
    var createdAt: Date
    var lastCopiedAt: Date
    var isPinned: Bool
    var imageData: Data?
    var imageWidth: Int?
    var imageHeight: Int?
    var imageFormat: String?

    init(
        id: UUID = UUID(),
        content: String,
        kind: ClipboardKind,
        createdAt: Date = Date(),
        lastCopiedAt: Date = Date(),
        isPinned: Bool = false,
        imageData: Data? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        imageFormat: String? = nil
    ) {
        self.id = id
        self.content = content
        self.kind = kind
        self.createdAt = createdAt
        self.lastCopiedAt = lastCopiedAt
        self.isPinned = isPinned
        self.imageData = imageData
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageFormat = imageFormat
    }

    var title: String {
        switch kind {
        case .image:
            if let dimensionsLabel {
                return "Image \(dimensionsLabel)"
            }

            return "Image"
        case .text, .url:
            break
        }

        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n", with: "  ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized.isEmpty {
            return "Empty clipboard entry"
        }

        return String(normalized.prefix(110))
    }

    var detail: String {
        if kind == .image {
            return [
                imageFormat?.uppercased(),
                dimensionsLabel,
                byteSizeLabel
            ]
            .compactMap { $0 }
            .joined(separator: "  •  ")
        }

        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return String(normalized.prefix(240))
    }

    var summaryLabel: String {
        if kind == .image {
            return byteSizeLabel ?? "Image"
        }

        return "\(content.count) chars"
    }

    var searchText: String {
        if kind == .image {
            return [
                content,
                imageFormat,
                dimensionsLabel,
                byteSizeLabel
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        }

        return content
    }

    var dimensionsLabel: String? {
        guard let imageWidth, let imageHeight else {
            return nil
        }

        return "\(imageWidth) x \(imageHeight)"
    }

    var byteSizeLabel: String? {
        guard let imageData else {
            return nil
        }

        return ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file)
    }
}
