import AppKit
import PastePawCore
import SwiftUI

struct QuickPanelView: View {
    @EnvironmentObject private var store: ClipboardHistoryStore
    let onHoverChanged: (Bool) -> Void
    let onClose: () -> Void

    var body: some View {
        expandedBody
        .onHover(perform: onHoverChanged)
    }

    private var expandedBody: some View {
        VStack(spacing: 12) {
            header

            if store.recentQuickPanelItems.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.recentQuickPanelItems) { item in
                            QuickPanelCard(item: item)
                                .environmentObject(store)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 4)
                }
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(panelBackground(cornerRadius: 22))
    }

    private var header: some View {
        HStack(spacing: 12) {
            CatMascotView(size: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text(store.localized(.quickPanelTitle))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(PastePawTheme.cocoa)

                Text(store.localized(.quickPanelSubtitle))
                    .font(.caption)
                    .foregroundStyle(PastePawTheme.coffee.opacity(0.7))
            }

            Spacer()

            Text(store.quickPanelShortcut.displayText)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(PastePawTheme.cocoa)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.72), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(PastePawTheme.warmCream, lineWidth: 1)
                )

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            .foregroundStyle(PastePawTheme.coffee)
            .background(.white.opacity(0.68), in: Circle())
            .help(store.localized(.close))
        }
        .padding(.horizontal, 18)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(PastePawTheme.caramel)

            Text(store.localized(.emptyHistoryHint))
                .font(.callout)
                .foregroundStyle(PastePawTheme.coffee.opacity(0.72))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func panelBackground(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThickMaterial)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            PastePawTheme.cream.opacity(0.94),
                            PastePawTheme.warmCream.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(PastePawTheme.caramel.opacity(0.32), lineWidth: 1)
        }
    }
}

private struct QuickPanelCard: View {
    @EnvironmentObject private var store: ClipboardHistoryStore
    let item: ClipboardHistoryItem

    var body: some View {
        Button {
            store.copyToPasteboard(item)
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 8) {
                    Label(title, systemImage: symbolName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(cardAccent, in: RoundedRectangle(cornerRadius: 8))

                content
                    .padding(.horizontal, 10)

                Spacer(minLength: 0)

                Text(item.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(PastePawTheme.coffee.opacity(0.58))
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }
            .frame(width: 148, height: 154)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(PastePawTheme.warmCream, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help(store.localized(.copyHelp))
    }

    private var symbolName: String {
        switch item.content {
        case .text:
            "text.alignleft"
        case .image:
            "photo.fill"
        }
    }

    private var title: String {
        switch item.content {
        case .text:
            store.localized(.textClipping)
        case .image:
            store.localized(.image)
        }
    }

    private var cardAccent: Color {
        switch item.content {
        case .text:
            PastePawTheme.caramel
        case .image:
            PastePawTheme.blush
        }
    }

    @ViewBuilder
    private var content: some View {
        switch item.content {
        case .text(let text):
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.system(size: 12))
                .foregroundStyle(PastePawTheme.cocoa)
                .lineLimit(5)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .image(let payload):
            if let image = NSImage(contentsOf: store.imagesDirectory.appendingPathComponent(payload.fileName)) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 128, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(PastePawTheme.warmCream.opacity(0.7), lineWidth: 1)
                    )
            } else {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(PastePawTheme.blush)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
