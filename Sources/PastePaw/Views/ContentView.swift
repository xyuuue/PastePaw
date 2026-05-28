import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ClipboardHistoryStore

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            if let error = store.lastError {
                ErrorBanner(message: error)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)
            }

            if store.filteredItems.isEmpty {
                EmptyHistoryView(hasSearch: !store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(store.filteredItems) { item in
                            ClipboardCard(item: item)
                                .environmentObject(store)
                        }
                    }
                    .padding(18)
                }
            }
        }
        .background(PastePawTheme.cream)
        .toolbar {
            ToolbarItem {
                SettingsLink {
                    Image(systemName: "gearshape.fill")
                }
                .help(store.localized(.settingsHelp))
            }
        }
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var store: ClipboardHistoryStore

    var body: some View {
        HStack(spacing: 16) {
            CatMascotView(size: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text("PastePaw")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(PastePawTheme.cocoa)

                Text(store.localized(.historySubtitle))
                    .font(.callout)
                    .foregroundStyle(PastePawTheme.coffee.opacity(0.75))
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(PastePawTheme.caramel)

                TextField(store.localized(.searchPlaceholder), text: $store.searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 230)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(PastePawTheme.warmCream, lineWidth: 1)
            )
        }
        .padding(18)
    }
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .lineLimit(2)
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.white)
        .padding(10)
        .background(PastePawTheme.blush, in: RoundedRectangle(cornerRadius: 8))
    }
}
