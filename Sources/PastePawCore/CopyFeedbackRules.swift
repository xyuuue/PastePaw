import Foundation

public enum CopyFeedbackRules {
    public static let visibleDurationNanoseconds: UInt64 = 900_000_000

    public static func isShowingFeedback(activeItemID: UUID?, itemID: UUID) -> Bool {
        activeItemID == itemID
    }

    public static func copyButtonSystemImage(isShowingFeedback: Bool) -> String {
        isShowingFeedback ? "checkmark.circle.fill" : "doc.on.clipboard"
    }
}
