import Foundation

public enum QuickPanelDismissalDecision: Equatable, Sendable {
    case cancelScheduledHide
    case scheduleHide
}

public enum QuickPanelDismissalRules {
    public static func decision(
        isHovering: Bool,
        dismissalMode: QuickPanelDismissalMode,
        activeInteractionCount: Int
    ) -> QuickPanelDismissalDecision {
        guard dismissalMode == .mouseExit else {
            return .cancelScheduledHide
        }

        guard !isHovering else {
            return .cancelScheduledHide
        }

        guard activeInteractionCount <= 0 else {
            return .cancelScheduledHide
        }

        return .scheduleHide
    }
}
