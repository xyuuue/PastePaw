import PastePawCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ClipboardHistoryStore
    @State private var showsQuickPanelHistoryLimitWarning = false
    @State private var newTagName = ""

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
                HStack {
                    TextField(store.localized(.tagName), text: $newTagName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addTag)

                    Button(action: addTag) {
                        Label(store.localized(.addTag), systemImage: "plus")
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if store.tags.isEmpty {
                    Text(store.localized(.noTagsYet))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.tags) { tag in
                        TagManagementRow(tag: tag)
                            .environmentObject(store)
                    }
                }

                Text(store.localized(.taggedRetentionHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label(store.localized(.tags), systemImage: "tag")
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

                Picker(store.localized(.quickPanelDismissalMode), selection: $store.quickPanelDismissalMode) {
                    ForEach(QuickPanelDismissalMode.allCases) { mode in
                        Text(dismissalModeTitle(mode)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Picker(store.localized(.quickPanelWheelDirection), selection: $store.quickPanelWheelScrollDirection) {
                    ForEach(QuickPanelWheelScrollDirection.allCases) { direction in
                        Text(wheelDirectionTitle(direction)).tag(direction)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    Text(store.localized(.quickPanelHistoryItems))
                    Spacer()
                    TextField(store.localized(.quickPanelHistoryItems), value: quickPanelHistoryCountBinding, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 72)
                    Stepper(
                        store.localized(.quickPanelHistoryItems),
                        value: quickPanelHistoryCountBinding,
                        in: ClipboardHistoryStore.quickPanelHistoryRange
                    )
                    .labelsHidden()
                }

                if showsQuickPanelHistoryLimitWarning {
                    Label(store.localized(.quickPanelHistoryMaxWarning), systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Text(store.localized(.quickPanelSettingsHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(store.localized(.quickPanelDismissalHint))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(store.localized(.quickPanelWheelDirectionHint))
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

    private var quickPanelHistoryCountBinding: Binding<Int> {
        Binding(
            get: {
                store.quickPanelHistoryCount
            },
            set: { newCount in
                showsQuickPanelHistoryLimitWarning = newCount > ClipboardHistoryStore.quickPanelHistoryRange.upperBound
                store.quickPanelHistoryCount = newCount
            }
        )
    }

    private func addTag() {
        guard let tag = store.createTag(named: newTagName) else {
            return
        }

        store.selectedQuickPanelTagID = tag.id
        newTagName = ""
    }

    private func dismissalModeTitle(_ mode: QuickPanelDismissalMode) -> String {
        switch mode {
        case .mouseExit:
            return store.localized(.quickPanelDismissOnMouseExit)
        case .shortcutToggle:
            return store.localized(.quickPanelDismissWithShortcut)
        }
    }

    private func wheelDirectionTitle(_ direction: QuickPanelWheelScrollDirection) -> String {
        switch direction {
        case .wheelUpMovesRight:
            return store.localized(.quickPanelWheelUpMovesRight)
        case .wheelUpMovesLeft:
            return store.localized(.quickPanelWheelUpMovesLeft)
        }
    }
}

private struct TagManagementRow: View {
    @EnvironmentObject private var store: ClipboardHistoryStore
    let tag: ClipboardTag
    @State private var showsColorPicker = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "tag.fill")
                .foregroundStyle(TagColorSwatch.color(hex: currentTag.colorHex))

            TextField(store.localized(.tagName), text: tagNameBinding)
                .textFieldStyle(.roundedBorder)

            Button {
                showsColorPicker.toggle()
            } label: {
                Circle()
                    .fill(TagColorSwatch.color(hex: currentTag.colorHex))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(PastePawTheme.warmCream, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showsColorPicker, arrowEdge: .trailing) {
                TagColorPickerPopover(
                    selectedColorHex: currentTag.colorHex,
                    onSelect: { colorHex in
                        store.updateTagColor(tag, colorHex: colorHex)
                        showsColorPicker = false
                    }
                )
            }

            Button(role: .destructive) {
                store.deleteTag(tag)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help(store.localized(.delete))
        }
    }

    private var currentTag: ClipboardTag {
        store.tags.first(where: { $0.id == tag.id }) ?? tag
    }

    private var tagNameBinding: Binding<String> {
        Binding(
            get: {
                store.tags.first(where: { $0.id == tag.id })?.name ?? tag.name
            },
            set: { newName in
                store.renameTag(tag, to: newName)
            }
        )
    }
}

private struct TagColorPickerPopover: View {
    let selectedColorHex: String
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(ClipboardTag.colorOptions) { option in
                Button {
                    onSelect(option.hex)
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(TagColorSwatch.color(hex: option.hex))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(PastePawTheme.warmCream, lineWidth: 1)
                            )

                        Text(option.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(PastePawTheme.cocoa)

                        Spacer()

                        if selectedColorHex == option.hex {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(TagColorSwatch.color(hex: option.hex))
                        }
                    }
                    .frame(width: 148, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        selectedColorHex == option.hex ? TagColorSwatch.color(hex: option.hex).opacity(0.12) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
    }
}
