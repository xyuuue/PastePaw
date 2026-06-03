import AppKit
import Foundation
import PastePawCore

@MainActor
final class ClipboardHistoryStore: ObservableObject {
    static let shared = ClipboardHistoryStore()

    @Published private(set) var items: [ClipboardHistoryItem] = []
    @Published private(set) var tags: [ClipboardTag] = []
    @Published var searchText = ""
    @Published var selectedQuickPanelTagID: UUID?
    @Published var retentionDays: Int {
        didSet {
            UserDefaults.standard.set(retentionDays, forKey: Self.retentionDaysKey)
            applyRetentionAndSave()
        }
    }
    @Published var menuHistoryCount: Int {
        didSet {
            let boundedCount = min(max(menuHistoryCount, Self.menuHistoryRange.lowerBound), Self.menuHistoryRange.upperBound)
            if boundedCount != menuHistoryCount {
                menuHistoryCount = boundedCount
                return
            }

            UserDefaults.standard.set(menuHistoryCount, forKey: Self.menuHistoryCountKey)
        }
    }
    @Published var quickPanelHistoryCount: Int {
        didSet {
            let boundedCount = min(max(quickPanelHistoryCount, Self.quickPanelHistoryRange.lowerBound), Self.quickPanelHistoryRange.upperBound)
            if boundedCount != quickPanelHistoryCount {
                quickPanelHistoryCount = boundedCount
                return
            }

            UserDefaults.standard.set(quickPanelHistoryCount, forKey: Self.quickPanelHistoryCountKey)
        }
    }
    @Published var quickPanelShortcut: PastePawKeyboardShortcut {
        didSet {
            UserDefaults.standard.set(encodedShortcut(quickPanelShortcut), forKey: Self.quickPanelShortcutKey)
        }
    }
    @Published var quickPanelDismissalMode: QuickPanelDismissalMode {
        didSet {
            UserDefaults.standard.set(quickPanelDismissalMode.rawValue, forKey: Self.quickPanelDismissalModeKey)
        }
    }
    @Published var appLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(appLanguage.rawValue, forKey: Self.appLanguageKey)
        }
    }
    @Published private(set) var quickPanelCustomTitle: String?
    @Published private(set) var lastError: String?

    static let retentionOptions = [1, 3, 5]
    static let menuHistoryRange = 1...15
    static let quickPanelHistoryRange = 3...50
    private static let retentionDaysKey = "retentionDays"
    private static let menuHistoryCountKey = "menuHistoryCount"
    private static let quickPanelHistoryCountKey = "quickPanelHistoryCount"
    private static let quickPanelShortcutKey = "quickPanelShortcut"
    private static let quickPanelDismissalModeKey = "quickPanelDismissalMode"
    private static let appLanguageKey = "appLanguage"
    private static let quickPanelCustomTitleKey = "quickPanelCustomTitle"

    private let fileManager: FileManager
    private let rootDirectory: URL
    private let metadataURL: URL
    private let tagsURL: URL
    let imagesDirectory: URL
    private var monitor: ClipboardMonitor?

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.rootDirectory = supportDirectory.appendingPathComponent("PastePaw", isDirectory: true)
        self.metadataURL = rootDirectory.appendingPathComponent("history.json")
        self.tagsURL = rootDirectory.appendingPathComponent("tags.json")
        self.imagesDirectory = rootDirectory.appendingPathComponent("Images", isDirectory: true)

        let savedRetentionDays = UserDefaults.standard.integer(forKey: Self.retentionDaysKey)
        self.retentionDays = Self.retentionOptions.contains(savedRetentionDays) ? savedRetentionDays : 3
        let savedMenuHistoryCount = UserDefaults.standard.integer(forKey: Self.menuHistoryCountKey)
        self.menuHistoryCount = Self.menuHistoryRange.contains(savedMenuHistoryCount) ? savedMenuHistoryCount : 5
        let savedQuickPanelHistoryCount = UserDefaults.standard.integer(forKey: Self.quickPanelHistoryCountKey)
        self.quickPanelHistoryCount = Self.quickPanelHistoryRange.contains(savedQuickPanelHistoryCount) ? savedQuickPanelHistoryCount : 7
        self.quickPanelShortcut = Self.decodedShortcut() ?? .defaultQuickPanel
        let savedQuickPanelDismissalMode = UserDefaults.standard.string(forKey: Self.quickPanelDismissalModeKey)
            .flatMap(QuickPanelDismissalMode.init(rawValue:))
        self.quickPanelDismissalMode = savedQuickPanelDismissalMode ?? .defaultMode
        let savedLanguage = UserDefaults.standard.string(forKey: Self.appLanguageKey)
            .flatMap(AppLanguage.init(rawValue:))
        self.appLanguage = savedLanguage ?? .english
        if let savedQuickPanelTitle = UserDefaults.standard.string(forKey: Self.quickPanelCustomTitleKey) {
            self.quickPanelCustomTitle = ClipboardBoardNameRules.normalizedCustomName(savedQuickPanelTitle)
        } else {
            self.quickPanelCustomTitle = nil
        }

        loadTags()
        load()
        applyRetentionAndSave()
        startMonitoring()
    }

    func localized(_ key: LocalizedText.Key) -> String {
        LocalizedText.text(key, language: appLanguage)
    }

    var quickPanelTitle: String {
        quickPanelCustomTitle ?? localized(.quickPanelTitle)
    }

    var filteredItems: [ClipboardHistoryItem] {
        HistoryRules.orderedItems(items).filter {
            HistoryRules.matchesSearch($0, query: searchText)
        }
    }

    var recentMenuItems: [ClipboardHistoryItem] {
        Array(HistoryRules.orderedItems(items).prefix(menuHistoryCount))
    }

    var recentQuickPanelItems: [ClipboardHistoryItem] {
        Array(
            HistoryRules.orderedItems(items)
                .filter { HistoryRules.matchesTag($0, selectedTagID: selectedQuickPanelTagID) }
                .prefix(quickPanelHistoryCount)
        )
    }

    func tags(for item: ClipboardHistoryItem) -> [ClipboardTag] {
        item.tagIDs.compactMap { tagID in
            tags.first { $0.id == tagID }
        }
    }

    func createTag(named rawName: String) -> ClipboardTag? {
        let name = normalizedTagName(rawName)
        guard !name.isEmpty else {
            return nil
        }

        if let existingTag = tags.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return existingTag
        }

        let tag = ClipboardTag(name: name, colorHex: nextTagColorHex())
        tags.append(tag)
        saveTags()
        return tag
    }

    func renameTag(_ tag: ClipboardTag, to rawName: String) {
        let name = normalizedTagName(rawName)
        guard !name.isEmpty else {
            return
        }
        guard !tags.contains(where: { $0.id != tag.id && $0.name.caseInsensitiveCompare(name) == .orderedSame }) else {
            return
        }
        guard let index = tags.firstIndex(where: { $0.id == tag.id }) else {
            return
        }

        tags[index].name = name
        saveTags()
    }

    func updateTagColor(_ tag: ClipboardTag, colorHex: String) {
        guard ClipboardTag.colorHexes.contains(colorHex) else {
            return
        }
        guard let index = tags.firstIndex(where: { $0.id == tag.id }) else {
            return
        }

        tags[index].colorHex = colorHex
        saveTags()
    }

    func deleteTag(_ tag: ClipboardTag) {
        tags.removeAll { $0.id == tag.id }
        if selectedQuickPanelTagID == tag.id {
            selectedQuickPanelTagID = nil
        }

        for index in items.indices {
            items[index].tagIDs.removeAll { $0 == tag.id }
        }

        saveTags()
        applyRetentionAndSave()
    }

    func toggleTag(_ tag: ClipboardTag, for item: ClipboardHistoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        if items[index].tagIDs.contains(tag.id) {
            items[index].tagIDs.removeAll { $0 == tag.id }
        } else {
            items[index].tagIDs.append(tag.id)
        }

        applyRetentionAndSave()
    }

    func resetQuickPanelShortcut() {
        quickPanelShortcut = .defaultQuickPanel
    }

    func renameQuickPanelTitle(to rawTitle: String) {
        quickPanelCustomTitle = ClipboardBoardNameRules.normalizedCustomName(rawTitle)

        if let quickPanelCustomTitle {
            UserDefaults.standard.set(quickPanelCustomTitle, forKey: Self.quickPanelCustomTitleKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.quickPanelCustomTitleKey)
        }
    }

    func startMonitoring() {
        if monitor == nil {
            monitor = ClipboardMonitor { [weak self] in
                self?.capturePasteboard()
            }
        }

        monitor?.start()
    }

    func capturePasteboard() {
        do {
            guard let item = try PasteboardReader.readCurrentItem(imagesDirectory: imagesDirectory) else {
                return
            }

            items.insert(item, at: 0)
            applyRetentionAndSave()
            lastError = nil
        } catch {
            lastError = "Could not save clipboard item: \(error.localizedDescription)"
        }
    }

    func copyToPasteboard(_ item: ClipboardHistoryItem) {
        do {
            let changeCount = try PasteboardReader.writeToPasteboard(item, imagesDirectory: imagesDirectory)
            monitor?.skipNextChangeCount(changeCount)
            lastError = nil
        } catch {
            lastError = "Could not copy item back to clipboard: \(error.localizedDescription)"
        }
    }

    func togglePin(_ item: ClipboardHistoryItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        items[index].isPinned.toggle()
        applyRetentionAndSave()
    }

    func delete(_ item: ClipboardHistoryItem) {
        items.removeAll { $0.id == item.id }

        if case .image(let payload) = item.content {
            try? fileManager.removeItem(at: imagesDirectory.appendingPathComponent(payload.fileName))
        }

        save()
    }

    func clearUnpinned() {
        let removedItems = items.filter { !$0.isPinned && $0.tagIDs.isEmpty }
        items.removeAll { !$0.isPinned && $0.tagIDs.isEmpty }

        for item in removedItems {
            if case .image(let payload) = item.content {
                try? fileManager.removeItem(at: imagesDirectory.appendingPathComponent(payload.fileName))
            }
        }

        save()
    }

    private func applyRetentionAndSave() {
        let retained = HistoryRules.retainedItems(items, retentionDays: retentionDays)
        removeImageFiles(for: items.filter { item in
            !retained.contains(where: { $0.id == item.id })
        })
        items = retained
        save()
    }

    private func load() {
        do {
            try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)

            guard fileManager.fileExists(atPath: metadataURL.path) else {
                items = []
                return
            }

            let data = try Data(contentsOf: metadataURL)
            items = try JSONDecoder().decode([ClipboardHistoryItem].self, from: data)
            lastError = nil
        } catch {
            items = []
            lastError = "Could not load clipboard history: \(error.localizedDescription)"
        }
    }

    private func loadTags() {
        do {
            try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)

            guard fileManager.fileExists(atPath: tagsURL.path) else {
                tags = []
                return
            }

            let data = try Data(contentsOf: tagsURL)
            tags = try JSONDecoder().decode([ClipboardTag].self, from: data)
            lastError = nil
        } catch {
            tags = []
            lastError = "Could not load tags: \(error.localizedDescription)"
        }
    }

    private func save() {
        do {
            try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(items)
            try data.write(to: metadataURL, options: .atomic)
            lastError = nil
        } catch {
            lastError = "Could not save clipboard history: \(error.localizedDescription)"
        }
    }

    private func saveTags() {
        do {
            try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(tags)
            try data.write(to: tagsURL, options: .atomic)
            lastError = nil
        } catch {
            lastError = "Could not save tags: \(error.localizedDescription)"
        }
    }

    private func removeImageFiles(for removedItems: [ClipboardHistoryItem]) {
        for item in removedItems {
            if case .image(let payload) = item.content {
                try? fileManager.removeItem(at: imagesDirectory.appendingPathComponent(payload.fileName))
            }
        }
    }

    private static func decodedShortcut() -> PastePawKeyboardShortcut? {
        guard let data = UserDefaults.standard.data(forKey: quickPanelShortcutKey) else {
            return nil
        }

        return try? JSONDecoder().decode(PastePawKeyboardShortcut.self, from: data)
    }

    private func encodedShortcut(_ shortcut: PastePawKeyboardShortcut) -> Data? {
        try? JSONEncoder().encode(shortcut)
    }

    private func normalizedTagName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func nextTagColorHex() -> String {
        ClipboardTag.colorHexes[tags.count % ClipboardTag.colorHexes.count]
    }
}
