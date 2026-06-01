import Foundation

public enum QuickPanelDismissalMode: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case mouseExit
    case shortcutToggle

    public static let defaultMode: QuickPanelDismissalMode = .mouseExit

    public var id: String { rawValue }
}
