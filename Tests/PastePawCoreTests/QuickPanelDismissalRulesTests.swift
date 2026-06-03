import Testing
@testable import PastePawCore

struct QuickPanelDismissalRulesTests {
    @Test func hoverExitDuringInteractiveMenuDoesNotScheduleHide() {
        let decision = QuickPanelDismissalRules.decision(
            isHovering: false,
            dismissalMode: .mouseExit,
            activeInteractionCount: 1
        )

        #expect(decision == .cancelScheduledHide)
    }

    @Test func hoverExitSchedulesHideWhenMouseExitModeHasNoActiveInteraction() {
        let decision = QuickPanelDismissalRules.decision(
            isHovering: false,
            dismissalMode: .mouseExit,
            activeInteractionCount: 0
        )

        #expect(decision == .scheduleHide)
    }

    @Test func shortcutToggleModeNeverSchedulesMouseExitHide() {
        let decision = QuickPanelDismissalRules.decision(
            isHovering: false,
            dismissalMode: .shortcutToggle,
            activeInteractionCount: 0
        )

        #expect(decision == .cancelScheduledHide)
    }
}
