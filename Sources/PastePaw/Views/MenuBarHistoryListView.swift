import AppKit
import PastePawCore
import SwiftUI

struct MenuBarHistoryListView: View {
    @EnvironmentObject private var store: ClipboardHistoryStore
    let items: [ClipboardHistoryItem]
    let onCopy: (ClipboardHistoryItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "pawprint.fill")
                    .foregroundStyle(PastePawTheme.caramel)

                Text(store.localized(.menuBarHistoryItems))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(PastePawTheme.cocoa)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 6) {
                    ForEach(items) { item in
                        MenuBarHistoryRow(item: item, onCopy: onCopy)
                            .environmentObject(store)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 292, height: menuHeight)
        .background(PastePawTheme.cream.opacity(0.84))
    }

    private var menuHeight: CGFloat {
        min(max(CGFloat(items.count) * 58 + 42, 116), 336)
    }
}

private struct MenuBarHistoryRow: View {
    @EnvironmentObject private var store: ClipboardHistoryStore
    let item: ClipboardHistoryItem
    let onCopy: (ClipboardHistoryItem) -> Void

    var body: some View {
        Button {
            onCopy(item)
        } label: {
            HStack(spacing: 9) {
                preview

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(PastePawTheme.cocoa)
                            .lineLimit(1)

                        if item.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(PastePawTheme.caramel)
                        }
                    }

                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(PastePawTheme.coffee.opacity(0.68))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(8)
            .frame(height: 52)
            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(item.isPinned ? PastePawTheme.caramel.opacity(0.75) : PastePawTheme.warmCream, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .help(store.localized(.copyHelp))
    }

    private var title: String {
        switch item.content {
        case .text:
            return store.localized(.textClipping)
        case .image(let payload):
            if let width = payload.width, let height = payload.height {
                return "\(store.localized(.image)) \(Int(width))x\(Int(height))"
            }
            return store.localized(.imageClipping)
        }
    }

    private var subtitle: String {
        switch item.content {
        case .text(let text):
            let oneLine = text
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return oneLine.isEmpty ? item.createdAt.formatted(date: .abbreviated, time: .shortened) : oneLine
        case .image(let payload):
            let size = ByteCountFormatter.string(fromByteCount: Int64(payload.byteCount), countStyle: .file)
            return "\(item.createdAt.formatted(date: .omitted, time: .shortened)) · \(size)"
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch item.content {
        case .text:
            Image(systemName: "text.alignleft")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(PastePawTheme.caramel)
                .frame(width: 34, height: 34)
                .background(PastePawTheme.warmCream.opacity(0.55), in: RoundedRectangle(cornerRadius: 7))
        case .image(let payload):
            if let image = NSImage(contentsOf: store.imagesDirectory.appendingPathComponent(payload.fileName)) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PastePawTheme.blush)
                    .frame(width: 34, height: 34)
                    .background(PastePawTheme.warmCream.opacity(0.55), in: RoundedRectangle(cornerRadius: 7))
            }
        }
    }
}
