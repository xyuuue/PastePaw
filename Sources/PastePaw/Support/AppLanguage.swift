import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case chinese

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .chinese:
            return "中文"
        }
    }
}

enum LocalizedText {
    static func text(_ key: Key, language: AppLanguage) -> String {
        switch language {
        case .english:
            return english[key] ?? key.rawValue
        case .chinese:
            return chinese[key] ?? key.rawValue
        }
    }

    enum Key: String {
        case openPastePaw
        case noClippings
        case settings
        case quit
        case pinnedPrefix
        case image
        case historySubtitle
        case quickPanelHomeHint
        case searchPlaceholder
        case settingsHelp
        case noMatchingText
        case emptySearchHint
        case emptyHistoryHint
        case pinned
        case copyHelp
        case pin
        case unpin
        case delete
        case textClipping
        case imageClipping
        case imageUnavailable
        case retention
        case keepNormalItems
        case day
        case days
        case pinnedRetentionHint
        case menuBar
        case menuBarHistoryItems
        case menuBarHistoryHint
        case quickPanel
        case quickPanelTitle
        case quickPanelSubtitle
        case quickPanelCollapsedHint
        case quickPanelShortcut
        case quickPanelHistoryItems
        case quickPanelHistoryMaxWarning
        case quickPanelSettingsHint
        case pressShortcut
        case resetShortcut
        case close
        case language
        case appLanguage
        case privacy
        case clearNonPinned
        case privacyHint
    }

    private static let english: [Key: String] = [
        .openPastePaw: "Open PastePaw",
        .noClippings: "No clippings yet",
        .settings: "Settings...",
        .quit: "Quit PastePaw",
        .pinnedPrefix: "Pinned: ",
        .image: "Image",
        .historySubtitle: "FuFu keeps recent text and images ready for Cmd+V.",
        .quickPanelHomeHint: "Press %@ to open the quick clipboard panel.",
        .searchPlaceholder: "Search text history",
        .settingsHelp: "Settings",
        .noMatchingText: "No matching text clippings",
        .emptySearchHint: "Images stay browseable by time, and text can be searched here.",
        .emptyHistoryHint: "Copy text or an image in any app and FuFu will keep it here.",
        .pinned: "Pinned",
        .copyHelp: "Copy back to clipboard",
        .pin: "Pin",
        .unpin: "Unpin",
        .delete: "Delete",
        .textClipping: "Text clipping",
        .imageClipping: "Image clipping",
        .imageUnavailable: "Image file is unavailable",
        .retention: "Retention",
        .keepNormalItems: "Keep normal items",
        .day: "day",
        .days: "days",
        .pinnedRetentionHint: "Pinned items are kept until you unpin or delete them.",
        .menuBar: "Menu Bar",
        .menuBarHistoryItems: "Menu bar history items",
        .menuBarHistoryHint: "These items appear in the menu bar menu for one-click copy back to the clipboard.",
        .quickPanel: "Quick Panel",
        .quickPanelTitle: "FuFu Clipboard",
        .quickPanelSubtitle: "Click an item to copy it back. Move the mouse away to close the panel.",
        .quickPanelCollapsedHint: "Hover to open recent clips",
        .quickPanelShortcut: "Shortcut",
        .quickPanelHistoryItems: "Panel history items",
        .quickPanelHistoryMaxWarning: "Maximum is 50 items.",
        .quickPanelSettingsHint: "Press the shortcut to show the bottom panel. The default shortcut is Option + Space.",
        .pressShortcut: "Press shortcut",
        .resetShortcut: "Reset shortcut",
        .close: "Close",
        .language: "Language",
        .appLanguage: "App language",
        .privacy: "Privacy",
        .clearNonPinned: "Clear Non-Pinned History",
        .privacyHint: "PastePaw stores history locally in Application Support and does not sync or upload it."
    ]

    private static let chinese: [Key: String] = [
        .openPastePaw: "打开 PastePaw",
        .noClippings: "还没有剪贴记录",
        .settings: "设置...",
        .quit: "退出 PastePaw",
        .pinnedPrefix: "置顶: ",
        .image: "图片",
        .historySubtitle: "FuFu 会帮你保存最近复制的文字和图片，随时可用 Cmd+V。",
        .quickPanelHomeHint: "按 %@ 开启快捷剪贴浮窗。",
        .searchPlaceholder: "搜索文字历史",
        .settingsHelp: "设置",
        .noMatchingText: "没有匹配的文字记录",
        .emptySearchHint: "图片会按时间保留，文字内容可以在这里搜索。",
        .emptyHistoryHint: "复制任意文字或图片后，FuFu 会把它保存到这里。",
        .pinned: "已置顶",
        .copyHelp: "复制回剪贴板",
        .pin: "置顶",
        .unpin: "取消置顶",
        .delete: "删除",
        .textClipping: "文字剪贴",
        .imageClipping: "图片剪贴",
        .imageUnavailable: "图片文件不可用",
        .retention: "保留时间",
        .keepNormalItems: "普通记录保留",
        .day: "天",
        .days: "天",
        .pinnedRetentionHint: "置顶内容会一直保留，直到你取消置顶或删除。",
        .menuBar: "菜单栏",
        .menuBarHistoryItems: "菜单栏历史数量",
        .menuBarHistoryHint: "这些记录会显示在菜单栏菜单中，点击即可复制回剪贴板。",
        .quickPanel: "快捷浮窗",
        .quickPanelTitle: "FuFu 剪贴板",
        .quickPanelSubtitle: "点击记录即可复制回剪贴板，鼠标移开后会自动关闭。",
        .quickPanelCollapsedHint: "悬停打开近期记录",
        .quickPanelShortcut: "快捷键",
        .quickPanelHistoryItems: "浮窗历史数量",
        .quickPanelHistoryMaxWarning: "最多 50 个。",
        .quickPanelSettingsHint: "按下快捷键即可打开底部浮窗，默认快捷键是 Option + Space。",
        .pressShortcut: "按下快捷键",
        .resetShortcut: "重置快捷键",
        .close: "关闭",
        .language: "语言",
        .appLanguage: "应用语言",
        .privacy: "隐私",
        .clearNonPinned: "清空非置顶历史",
        .privacyHint: "PastePaw 只在本机 Application Support 中保存历史，不同步也不上传。"
    ]
}
