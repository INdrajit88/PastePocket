import AppKit
import SwiftUI

struct ClipboardRowView: View {
    let item: ClipboardItem
    var shortcutIndex: Int? = nil
    let onCopy: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    private var shortcutKey: KeyEquivalent? {
        guard let index = shortcutIndex, index < 9 else { return nil }
        return KeyEquivalent(Character(String(index + 1)))
    }

    private static let timestampStyle = Date.RelativeFormatStyle(
        presentation: .named,
        unitsStyle: .abbreviated
    )

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onCopy) {
                HStack(alignment: .top, spacing: 12) {
                    if let previewImage {
                        Image(nsImage: previewImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 92, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.secondary.opacity(0.16))
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Label(kindTitle, systemImage: kindIcon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(item.isPinned ? .orange : .secondary)

                            if let index = shortcutIndex, index < 9 {
                                Text("⌘\(index + 1)")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(item.lastCopiedAt, format: Self.timestampStyle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(item.kind == .image ? 1 : 2)
                            .multilineTextAlignment(.leading)

                        if !item.detail.isEmpty {
                            Text(item.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(item.kind == .image ? 2 : 3)
                                .multilineTextAlignment(.leading)
                        }

                        Text(item.summaryLabel)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            VStack(spacing: 8) {
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                }
                .help("Copy back to the clipboard")

                Button(action: onTogglePin) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                }
                .help(item.isPinned ? "Unpin item" : "Pin item")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .help("Delete item")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .padding(.top, 12)
            .padding(.trailing, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(item.isPinned ? Color.orange.opacity(0.4) : Color.secondary.opacity(0.15))
        )
    }

    private var kindIcon: String {
        switch item.kind {
        case .text:
            return "doc.text"
        case .url:
            return "link"
        case .image:
            return "photo"
        }
    }

    private var kindTitle: String {
        switch item.kind {
        case .text:
            return "Text"
        case .url:
            return "URL"
        case .image:
            return "Image"
        }
    }

    private var previewImage: NSImage? {
        guard let imageData = item.imageData else {
            return nil
        }

        return NSImage(data: imageData)
    }
}
