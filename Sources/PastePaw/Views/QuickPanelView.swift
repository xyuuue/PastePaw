import AppKit
import PastePawCore
import SwiftUI

struct QuickPanelView: View {
    @EnvironmentObject private var store: ClipboardHistoryStore
    @State private var activeEditor: QuickPanelEditor?
    @State private var tagNameDraft = ""
    @State private var tagColorDraft = ClipboardTag.defaultColorHex
    @State private var itemTitleDraft = ""
    let onHoverChanged: (Bool) -> Void
    let onEditingChanged: (Bool) -> Void
    let onClose: () -> Void

    var body: some View {
        ZStack {
            expandedBody

            if let activeEditor {
                editorOverlay(for: activeEditor)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .onHover(perform: onHoverChanged)
        .onChange(of: activeEditor != nil) { _, isEditing in
            onEditingChanged(isEditing)
        }
    }

    private var expandedBody: some View {
        VStack(spacing: 10) {
            header
            tagSelector

            if store.recentQuickPanelItems.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(store.recentQuickPanelItems) { item in
                            QuickPanelCard(
                                item: item,
                                onRenameTitle: openItemTitleEditor,
                                onCreateAndAssignTag: openCreateTagEditor
                            )
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

                Text(store.localized(quickPanelSubtitleKey))
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

    private var tagSelector: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Spacer(minLength: 0)

                    HStack(spacing: 8) {
                        TagFilterButton(
                            title: store.localized(.allTags),
                            systemImage: "tray.full",
                            colorHex: ClipboardTag.defaultColorHex,
                            isSelected: store.selectedQuickPanelTagID == nil
                        ) {
                            store.selectedQuickPanelTagID = nil
                        }

                        ForEach(store.tags) { tag in
                            TagFilterButton(
                                title: tag.name,
                                systemImage: "tag.fill",
                                colorHex: tag.colorHex,
                                isSelected: store.selectedQuickPanelTagID == tag.id
                            ) {
                                store.selectedQuickPanelTagID = tag.id
                            }
                            .contextMenu {
                                Button {
                                    editQuickPanelTag(tag)
                                } label: {
                                    Label(store.localized(.editTag), systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    store.deleteTag(tag)
                                } label: {
                                    Label(store.localized(.delete), systemImage: "trash")
                                }
                            }
                        }

                        TagFilterButton(
                            title: store.localized(.newTag),
                            systemImage: "plus",
                            colorHex: "#8A735F",
                            isSelected: false
                        ) {
                            createQuickPanelTag()
                        }
                    }
                    .padding(.horizontal, 2)

                    Spacer(minLength: 0)
                }
                .frame(minWidth: proxy.size.width)
            }
        }
        .frame(height: 36)
        .padding(.horizontal, 18)
    }

    private var quickPanelSubtitleKey: LocalizedText.Key {
        switch store.quickPanelDismissalMode {
        case .mouseExit:
            return .quickPanelSubtitle
        case .shortcutToggle:
            return .quickPanelShortcutDismissSubtitle
        }
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

    private func createQuickPanelTag() {
        openCreateTagEditor(assigningTo: nil)
    }

    private func editQuickPanelTag(_ tag: ClipboardTag) {
        let currentTag = store.tags.first(where: { $0.id == tag.id }) ?? tag
        tagNameDraft = currentTag.name
        tagColorDraft = currentTag.colorHex
        activeEditor = .editTag(currentTag.id)
    }

    private func openCreateTagEditor(assigningTo item: ClipboardHistoryItem?) {
        tagNameDraft = ""
        tagColorDraft = store.suggestedTagColorHex()
        activeEditor = .createTag(assignToItemID: item?.id)
    }

    private func openItemTitleEditor(_ item: ClipboardHistoryItem) {
        itemTitleDraft = item.customTitle ?? defaultTitle(for: item)
        activeEditor = .renameItem(item.id)
    }

    private func closeEditor() {
        activeEditor = nil
    }

    @ViewBuilder
    private func editorOverlay(for editor: QuickPanelEditor) -> some View {
        ZStack {
            Rectangle()
                .fill(.black.opacity(0.12))
                .background(.ultraThinMaterial.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .onTapGesture(perform: closeEditor)

            switch editor {
            case .createTag:
                QuickPanelTagEditorSheet(
                    title: store.localized(.newTag),
                    confirmTitle: store.localized(.addTag),
                    name: $tagNameDraft,
                    colorHex: $tagColorDraft,
                    showsDelete: false,
                    onSave: saveActiveEditor,
                    onDelete: nil,
                    onCancel: closeEditor
                )
                .environmentObject(store)
            case .editTag(let tagID):
                QuickPanelTagEditorSheet(
                    title: store.localized(.editTag),
                    confirmTitle: store.localized(.save),
                    name: $tagNameDraft,
                    colorHex: $tagColorDraft,
                    showsDelete: true,
                    onSave: saveActiveEditor,
                    onDelete: { deleteTag(tagID: tagID) },
                    onCancel: closeEditor
                )
                .environmentObject(store)
            case .renameItem:
                QuickPanelTitleEditorSheet(
                    title: store.localized(.renameClipping),
                    clippingTitle: $itemTitleDraft,
                    onSave: saveActiveEditor,
                    onCancel: closeEditor
                )
                .environmentObject(store)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(10)
    }

    private func saveActiveEditor() {
        guard let activeEditor else {
            return
        }

        switch activeEditor {
        case .createTag(let itemID):
            guard let tag = store.createTag(named: tagNameDraft, colorHex: tagColorDraft) else {
                return
            }

            if let itemID,
               let item = store.items.first(where: { $0.id == itemID }),
               !item.tagIDs.contains(tag.id) {
                store.toggleTag(tag, for: item)
            }
            store.selectedQuickPanelTagID = tag.id
            closeEditor()
        case .editTag(let tagID):
            guard let tag = store.tags.first(where: { $0.id == tagID }) else {
                closeEditor()
                return
            }

            store.renameTag(tag, to: tagNameDraft)
            store.updateTagColor(tag, colorHex: tagColorDraft)
            closeEditor()
        case .renameItem(let itemID):
            guard let item = store.items.first(where: { $0.id == itemID }) else {
                closeEditor()
                return
            }

            store.renameTitle(for: item, to: itemTitleDraft)
            closeEditor()
        }
    }

    private func deleteTag(tagID: UUID) {
        guard let tag = store.tags.first(where: { $0.id == tagID }) else {
            closeEditor()
            return
        }

        store.deleteTag(tag)
        closeEditor()
    }

    private func defaultTitle(for item: ClipboardHistoryItem) -> String {
        switch item.content {
        case .text:
            return store.localized(.textClipping)
        case .image:
            return store.localized(.image)
        }
    }
}

private struct QuickPanelCard: View {
    @EnvironmentObject private var store: ClipboardHistoryStore
    @State private var copiedItemID: UUID?
    @State private var copyFeedbackTask: Task<Void, Never>?
    let item: ClipboardHistoryItem
    let onRenameTitle: (ClipboardHistoryItem) -> Void
    let onCreateAndAssignTag: (ClipboardHistoryItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                itemTitleEditor

                Spacer()

                Button {
                    store.togglePin(item)
                } label: {
                    Image(systemName: item.isPinned ? "pin.slash.fill" : "pin")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.94))
                .help(item.isPinned ? store.localized(.unpin) : store.localized(.pin))

                Menu {
                    tagMenuContent
                } label: {
                    Image(systemName: item.tagIDs.isEmpty ? "tag" : "tag.fill")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.94))
                .help(store.localized(.assignTags))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(cardAccent, in: RoundedRectangle(cornerRadius: 8))

            copyArea
        }
        .frame(width: 164, height: 168)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(cardBorderColor, lineWidth: isShowingCopyFeedback || item.isPinned ? 1.4 : 1)
        )
        .help(store.localized(.copyHelp))
        .onDisappear {
            copyFeedbackTask?.cancel()
        }
    }

    @ViewBuilder
    private var itemTitleEditor: some View {
        Label(title, systemImage: symbolName)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: 78, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                onRenameTitle(item)
            }
    }

    private var copyArea: some View {
        Button(action: copyItem) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 8) {
                    content
                        .padding(.horizontal, 10)

                    TagChipsView(tags: store.tags(for: item), limit: 2, compact: true)
                        .padding(.horizontal, 10)

                    Spacer(minLength: 0)

                    Text(item.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(PastePawTheme.coffee.opacity(0.58))
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                if isShowingCopyFeedback {
                    CopyFeedbackBadge(title: store.localized(.copiedFeedback))
                        .padding(8)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isShowingCopyFeedback ? store.localized(.copiedFeedback) : store.localized(.copyHelp))
    }

    private var isShowingCopyFeedback: Bool {
        CopyFeedbackRules.isShowingFeedback(activeItemID: copiedItemID, itemID: item.id)
    }

    private var cardBorderColor: Color {
        if isShowingCopyFeedback {
            return PastePawTheme.caramel.opacity(0.92)
        }

        return item.isPinned ? PastePawTheme.caramel : PastePawTheme.warmCream
    }

    private func copyItem() {
        guard store.copyToPasteboard(item) else {
            return
        }

        showCopyFeedback()
    }

    private func showCopyFeedback() {
        copyFeedbackTask?.cancel()

        withAnimation(.spring(response: 0.2, dampingFraction: 0.72)) {
            copiedItemID = item.id
        }

        copyFeedbackTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: CopyFeedbackRules.visibleDurationNanoseconds)

            guard !Task.isCancelled else {
                return
            }

            withAnimation(.easeOut(duration: 0.18)) {
                copiedItemID = nil
            }
        }
    }

    @ViewBuilder
    private var tagMenuContent: some View {
        if store.tags.isEmpty {
            Text(store.localized(.noTagsYet))
        } else {
            ForEach(store.tags) { tag in
                Button {
                    store.toggleTag(tag, for: item)
                } label: {
                    Label(tag.name, systemImage: item.tagIDs.contains(tag.id) ? "checkmark.circle.fill" : "circle")
                }
            }

            Divider()
        }

        Button {
            onCreateAndAssignTag(item)
        } label: {
            Label(store.localized(.newTag), systemImage: "plus")
        }
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
        item.customTitle ?? defaultTitle
    }

    private var defaultTitle: String {
        switch item.content {
        case .text:
            store.localized(.textClipping)
        case .image:
            store.localized(.image)
        }
    }

    private var cardAccent: Color {
        TagColorSwatch.color(
            hex: ClipboardItemAccentRules.quickPanelCardAccentColorHex(tags: store.tags(for: item))
        )
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

private struct CopyFeedbackBadge: View {
    let title: String

    var body: some View {
        Label(title, systemImage: "checkmark.circle.fill")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(PastePawTheme.caramel, in: Capsule())
            .shadow(color: PastePawTheme.caramel.opacity(0.25), radius: 5, y: 2)
    }
}

private enum QuickPanelEditor: Equatable {
    case createTag(assignToItemID: UUID?)
    case editTag(UUID)
    case renameItem(UUID)
}

private struct QuickPanelTagEditorSheet: View {
    @EnvironmentObject private var store: ClipboardHistoryStore
    let title: String
    let confirmTitle: String
    @Binding var name: String
    @Binding var colorHex: String
    let showsDelete: Bool
    let onSave: () -> Void
    let onDelete: (() -> Void)?
    let onCancel: () -> Void
    @FocusState private var isNameFocused: Bool

    private var canSave: Bool {
        !ClipboardTagRules.normalizedName(name).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: "tag.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(PastePawTheme.cocoa)

                Spacer()

                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .foregroundStyle(PastePawTheme.coffee)
            }

            TextField(store.localized(.tagName), text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFocused)
                .onSubmit {
                    if canSave {
                        onSave()
                    }
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(store.localized(.tagColor))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(PastePawTheme.coffee.opacity(0.72))

                HStack(spacing: 8) {
                    ForEach(ClipboardTag.colorOptions) { option in
                        Button {
                            colorHex = option.hex
                        } label: {
                            Circle()
                                .fill(TagColorSwatch.color(hex: option.hex))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(colorHex == option.hex ? PastePawTheme.cocoa : .white.opacity(0.72), lineWidth: colorHex == option.hex ? 2 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .help(option.name)
                    }
                }
            }

            HStack(spacing: 10) {
                if showsDelete, let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Label(store.localized(.delete), systemImage: "trash")
                    }
                    .buttonStyle(.borderless)
                }

                Spacer()

                Button(store.localized(.cancel), action: onCancel)
                    .buttonStyle(.borderless)

                Button(confirmTitle, action: onSave)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
            }
        }
        .padding(14)
        .frame(width: 340)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(PastePawTheme.warmCream, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 16, y: 8)
        .onAppear {
            isNameFocused = true
        }
    }
}

private struct QuickPanelTitleEditorSheet: View {
    @EnvironmentObject private var store: ClipboardHistoryStore
    let title: String
    @Binding var clippingTitle: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: "text.alignleft")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(PastePawTheme.cocoa)

                Spacer()

                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .foregroundStyle(PastePawTheme.coffee)
            }

            TextField(store.localized(.clippingTitle), text: $clippingTitle)
                .textFieldStyle(.roundedBorder)
                .focused($isTitleFocused)
                .onSubmit(onSave)

            HStack(spacing: 10) {
                Spacer()

                Button(store.localized(.cancel), action: onCancel)
                    .buttonStyle(.borderless)

                Button(store.localized(.save), action: onSave)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .frame(width: 320)
        .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(PastePawTheme.warmCream, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 16, y: 8)
        .onAppear {
            isTitleFocused = true
        }
    }
}

private struct TagFilterButton: View {
    let title: String
    let systemImage: String
    let colorHex: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let color = TagColorSwatch.color(hex: colorHex)

        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .lineLimit(1)
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? color : .white.opacity(0.68), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(color.opacity(isSelected ? 0.95 : 0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
