import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ClipboardHistoryStore

    var body: some View {
        Form {
            Section {
                Picker(store.localized(.keepNormalItems), selection: $store.retentionDays) {
                    ForEach(ClipboardHistoryStore.retentionOptions, id: \.self) { days in
                        Text("\(days) \(store.localized(days == 1 ? .day : .days))").tag(days)
                    }
                }
                .pickerStyle(.segmented)

                Text(store.localized(.pinnedRetentionHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label(store.localized(.retention), systemImage: "calendar")
            }

            Section {
                Stepper(value: $store.menuHistoryCount, in: ClipboardHistoryStore.menuHistoryRange) {
                    HStack {
                        Text(store.localized(.menuBarHistoryItems))
                        Spacer()
                        Text("\(store.menuHistoryCount)")
                            .foregroundStyle(.secondary)
                    }
                }

                Text(store.localized(.menuBarHistoryHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label(store.localized(.menuBar), systemImage: "menubar.rectangle")
            }

            Section {
                HStack {
                    Text(store.localized(.quickPanelShortcut))
                    Spacer()
                    ShortcutRecorderView(shortcut: $store.quickPanelShortcut)
                }

                Stepper(value: $store.quickPanelHistoryCount, in: ClipboardHistoryStore.quickPanelHistoryRange) {
                    HStack {
                        Text(store.localized(.quickPanelHistoryItems))
                        Spacer()
                        Text("\(store.quickPanelHistoryCount)")
                            .foregroundStyle(.secondary)
                    }
                }

                Text(store.localized(.quickPanelSettingsHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label(store.localized(.quickPanel), systemImage: "rectangle.bottomthird.inset.filled")
            }

            Section {
                Picker(store.localized(.appLanguage), selection: $store.appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Label(store.localized(.language), systemImage: "globe")
            }

            Section {
                Button(role: .destructive) {
                    store.clearUnpinned()
                } label: {
                    Label(store.localized(.clearNonPinned), systemImage: "trash")
                }

                Text(store.localized(.privacyHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label(store.localized(.privacy), systemImage: "lock.fill")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
