import AppKit
import SwiftUI
import PastePawCore

struct ClipboardCard: View {
    @EnvironmentObject private var store: ClipboardHistoryStore
    let item: ClipboardHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(PastePawTheme.caramel)
                    .frame(width: 34, height: 34)
                    .background(PastePawTheme.warmCream.opacity(0.55), in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(PastePawTheme.cocoa)

                        if item.isPinned {
                            Label(store.localized(.pinned), systemImage: "pin.fill")
                                .font(.caption)
                                .foregroundStyle(PastePawTheme.caramel)
                        }
                    }

                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(PastePawTheme.coffee.opacity(0.62))
                }

                Spacer()

                HStack(spacing: 6) {
                    Button {
                        store.copyToPasteboard(item)
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                    }
                    .help(store.localized(.copyHelp))

                    Button {
                        store.togglePin(item)
                    } label: {
                        Image(systemName: item.isPinned ? "pin.slash" : "pin")
                    }
                    .help(item.isPinned ? store.localized(.unpin) : store.localized(.pin))

                    Button(role: .destructive) {
                        store.delete(item)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .help(store.localized(.delete))
                }
                .buttonStyle(.borderless)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PastePawTheme.coffee)
            }

            contentPreview
        }
        .padding(14)
        .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(item.isPinned ? PastePawTheme.caramel : PastePawTheme.warmCream, lineWidth: item.isPinned ? 1.4 : 1)
        )
    }

    private var symbolName: String {
        switch item.content {
        case .text:
            return "text.quote"
        case .image:
            return "photo"
        }
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

    @ViewBuilder
    private var contentPreview: some View {
        switch item.content {
        case .text(let text):
            Text(text)
                .font(.body)
                .foregroundStyle(PastePawTheme.cocoa)
                .lineLimit(6)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(PastePawTheme.cream.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
        case .image(let payload):
            ImagePreview(fileURL: store.imagesDirectory.appendingPathComponent(payload.fileName), byteCount: payload.byteCount)
        }
    }
}

private struct ImagePreview: View {
    let fileURL: URL
    let byteCount: Int

    var body: some View {
        if let image = NSImage(contentsOf: fileURL) {
            VStack(alignment: .leading, spacing: 8) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .frame(maxWidth: .infinity)
                    .background(PastePawTheme.cream.opacity(0.48), in: RoundedRectangle(cornerRadius: 8))

                Text(ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file))
                    .font(.caption)
                    .foregroundStyle(PastePawTheme.coffee.opacity(0.66))
            }
        } else {
            Label(LocalizedText.text(.imageUnavailable, language: ClipboardHistoryStore.shared.appLanguage), systemImage: "photo.badge.exclamationmark")
                .foregroundStyle(PastePawTheme.blush)
                .padding(12)
        }
    }
}
