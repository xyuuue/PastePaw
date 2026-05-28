import SwiftUI

struct EmptyHistoryView: View {
    @EnvironmentObject private var store: ClipboardHistoryStore
    let hasSearch: Bool

    var body: some View {
        VStack(spacing: 14) {
            CatMascotView(size: 130)

            Text(hasSearch ? store.localized(.noMatchingText) : store.localized(.noClippings))
                .font(.title2.weight(.semibold))
                .foregroundStyle(PastePawTheme.cocoa)

            Text(hasSearch ? store.localized(.emptySearchHint) : store.localized(.emptyHistoryHint))
                .font(.callout)
                .foregroundStyle(PastePawTheme.coffee.opacity(0.72))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .padding(24)
    }
}
