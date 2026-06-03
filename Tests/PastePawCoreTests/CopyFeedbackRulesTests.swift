import Foundation
import Testing
@testable import PastePawCore

struct CopyFeedbackRulesTests {
    @Test func copyFeedbackUsesShortVisibleDuration() {
        #expect(CopyFeedbackRules.visibleDurationNanoseconds == 900_000_000)
    }

    @Test func onlyMatchingItemShowsCopyFeedback() {
        let copiedID = UUID()

        #expect(CopyFeedbackRules.isShowingFeedback(activeItemID: copiedID, itemID: copiedID))
        #expect(!CopyFeedbackRules.isShowingFeedback(activeItemID: copiedID, itemID: UUID()))
        #expect(!CopyFeedbackRules.isShowingFeedback(activeItemID: nil, itemID: copiedID))
    }

    @Test func copyFeedbackSwitchesSystemIcon() {
        #expect(CopyFeedbackRules.copyButtonSystemImage(isShowingFeedback: false) == "doc.on.clipboard")
        #expect(CopyFeedbackRules.copyButtonSystemImage(isShowingFeedback: true) == "checkmark.circle.fill")
    }
}
