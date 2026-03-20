import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ClipboardStore
    @State private var searchText = ""

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
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PasteMac")
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

                        ForEach(pinnedItems) { item in
                            ClipboardRowView(
                                item: item,
                                onCopy: { store.copy(item) },
                                onTogglePin: { store.togglePinned(item) },
                                onDelete: { store.delete(item) }
                            )
                        }
                    }

                    if !recentItems.isEmpty {
                        sectionLabel(pinnedItems.isEmpty ? "Recent" : "Recent Copies")

                        ForEach(recentItems) { item in
                            ClipboardRowView(
                                item: item,
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
            Image(systemName: "list.clipboard")
                .font(.system(size: 34))
                .foregroundStyle(.secondary)

            Text(searchText.isEmpty ? "Your clipboard history will appear here." : "No clipboard matches for that search.")
                .font(.headline)

            Text(searchText.isEmpty ? "Copy text or images anywhere on your Mac and PasteMac will keep a searchable history." : "Try a different keyword or clear the search field.")
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
