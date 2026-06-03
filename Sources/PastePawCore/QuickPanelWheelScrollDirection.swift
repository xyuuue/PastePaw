import Foundation

public enum QuickPanelWheelScrollDirection: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case wheelUpMovesRight
    case wheelUpMovesLeft

    public static let defaultDirection: QuickPanelWheelScrollDirection = .wheelUpMovesRight

    public var id: String { rawValue }

    var verticalDeltaMultiplier: Double {
        switch self {
        case .wheelUpMovesRight:
            return 1
        case .wheelUpMovesLeft:
            return -1
        }
    }
}
