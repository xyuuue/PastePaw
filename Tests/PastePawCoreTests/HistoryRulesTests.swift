import XCTest
@testable import PastePawCore

final class HistoryRulesTests: XCTestCase {
    func testPinnedItemsSortBeforeNormalItemsThenNewestFirst() {
        let now = Date()
        let oldPinned = ClipboardHistoryItem(createdAt: now.addingTimeInterval(-300), isPinned: true, content: .text("old pinned"))
        let newNormal = ClipboardHistoryItem(createdAt: now, isPinned: false, content: .text("new normal"))
        let newPinned = ClipboardHistoryItem(createdAt: now.addingTimeInterval(-100), isPinned: true, content: .text("new pinned"))

        let result = HistoryRules.orderedItems([newNormal, oldPinned, newPinned])

        XCTAssertEqual(result.map(\.id), [newPinned.id, oldPinned.id, newNormal.id])
    }

    func testRetentionKeepsPinnedItemsAndDropsExpiredNormalItems() {
        let now = Date()
        let expiredPinned = ClipboardHistoryItem(createdAt: now.addingTimeInterval(-5 * 24 * 60 * 60), isPinned: true, content: .text("keep"))
        let expiredNormal = ClipboardHistoryItem(createdAt: now.addingTimeInterval(-5 * 24 * 60 * 60), isPinned: false, content: .text("drop"))
        let freshNormal = ClipboardHistoryItem(createdAt: now.addingTimeInterval(-1 * 24 * 60 * 60), isPinned: false, content: .text("keep"))

        let result = HistoryRules.retainedItems([expiredPinned, expiredNormal, freshNormal], retentionDays: 3, now: now)

        XCTAssertEqual(Set(result.map(\.id)), Set([expiredPinned.id, freshNormal.id]))
    }

    func testTextSearchIsCaseInsensitiveAndImagesDoNotMatchTextQueries() {
        let text = ClipboardHistoryItem(content: .text("FuFu coffee note"))
        let image = ClipboardHistoryItem(content: .image(ImagePayload(fileName: "image.png", pasteboardType: "public.png", byteCount: 10)))

        XCTAssertTrue(HistoryRules.matchesSearch(text, query: "COFFEE"))
        XCTAssertFalse(HistoryRules.matchesSearch(image, query: "COFFEE"))
        XCTAssertTrue(HistoryRules.matchesSearch(image, query: " "))
    }
}
