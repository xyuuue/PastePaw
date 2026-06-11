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

    func testLegacyDecodedItemsDefaultTagIDsToEmpty() throws {
        let json = """
        {
          "content": {
            "text": {
              "_0": "legacy clipping"
            }
          },
          "createdAt": -978307200,
          "id": "00000000-0000-0000-0000-000000000001",
          "isPinned": false
        }
        """

        let item = try JSONDecoder().decode(ClipboardHistoryItem.self, from: Data(json.utf8))

        XCTAssertEqual(item.tagIDs, [])
    }

    func testLegacyDecodedItemsDefaultTagSortOrdersToEmpty() throws {
        let json = """
        {
          "content": {
            "text": {
              "_0": "legacy clipping"
            }
          },
          "createdAt": -978307200,
          "id": "00000000-0000-0000-0000-000000000001",
          "isPinned": false,
          "tagIDs": []
        }
        """

        let item = try JSONDecoder().decode(ClipboardHistoryItem.self, from: Data(json.utf8))

        XCTAssertEqual(item.tagSortOrders, [:])
    }

    func testRetentionKeepsTaggedItemsAndDropsExpiredNormalItems() {
        let now = Date()
        let tagID = UUID()
        let expiredTagged = ClipboardHistoryItem(
            createdAt: now.addingTimeInterval(-5 * 24 * 60 * 60),
            tagIDs: [tagID],
            content: .text("keep tagged")
        )
        let expiredNormal = ClipboardHistoryItem(
            createdAt: now.addingTimeInterval(-5 * 24 * 60 * 60),
            content: .text("drop normal")
        )

        let result = HistoryRules.retainedItems([expiredTagged, expiredNormal], retentionDays: 3, now: now)

        XCTAssertEqual(result.map(\.id), [expiredTagged.id])
    }

    func testTagFilteringMatchesSelectedTagsAndAllowsAllItems() {
        let firstTagID = UUID()
        let secondTagID = UUID()
        let item = ClipboardHistoryItem(tagIDs: [firstTagID, secondTagID], content: .text("tagged"))

        XCTAssertTrue(HistoryRules.matchesTag(item, selectedTagID: nil))
        XCTAssertTrue(HistoryRules.matchesTag(item, selectedTagID: firstTagID))
        XCTAssertTrue(HistoryRules.matchesTag(item, selectedTagID: secondTagID))
        XCTAssertFalse(HistoryRules.matchesTag(item, selectedTagID: UUID()))
    }

    func testSelectedTagOrderingUsesManualOrderBeforeDefaultFallback() {
        let tagID = UUID()
        let now = Date()
        let firstManual = ClipboardHistoryItem(
            createdAt: now.addingTimeInterval(-300),
            tagIDs: [tagID],
            tagSortOrders: [tagID: 0],
            content: .text("first manual")
        )
        let fallback = ClipboardHistoryItem(
            createdAt: now,
            tagIDs: [tagID],
            content: .text("fallback")
        )
        let secondManual = ClipboardHistoryItem(
            createdAt: now.addingTimeInterval(-100),
            tagIDs: [tagID],
            tagSortOrders: [tagID: 1],
            content: .text("second manual")
        )

        let result = HistoryRules.orderedItems([fallback, secondManual, firstManual], selectedTagID: tagID)

        XCTAssertEqual(result.map(\.id), [firstManual.id, secondManual.id, fallback.id])
    }

    func testReorderRulesMoveItemBeforeTarget() {
        let first = UUID()
        let second = UUID()
        let third = UUID()

        let result = ReorderRules.reorderedIDs(
            [first, second, third],
            moving: third,
            relativeTo: first,
            placement: .before
        )

        XCTAssertEqual(result, [third, first, second])
    }

    func testReorderRulesMoveItemAfterTarget() {
        let first = UUID()
        let second = UUID()
        let third = UUID()

        let result = ReorderRules.reorderedIDs(
            [first, second, third],
            moving: first,
            relativeTo: third,
            placement: .after
        )

        XCTAssertEqual(result, [second, third, first])
    }

    func testReorderRulesResolvePlacementFromDropLocation() {
        XCTAssertEqual(ReorderRules.placement(forLocationX: 24, targetWidth: 120), .before)
        XCTAssertEqual(ReorderRules.placement(forLocationX: 96, targetWidth: 120), .after)
    }

    func testClipboardTagDefaultsToFirstPaletteColor() {
        let tag = ClipboardTag(name: "Prompt")

        XCTAssertEqual(tag.colorHex, ClipboardTag.defaultColorHex)
    }

    func testClipboardTagColorOptionsUseReadableNames() {
        XCTAssertEqual(ClipboardTag.colorHexes, ClipboardTag.colorOptions.map(\.hex))
        XCTAssertTrue(ClipboardTag.colorOptions.allSatisfy { !$0.name.hasPrefix("#") })
    }

    func testLegacyDecodedTagsDefaultToFirstPaletteColor() throws {
        let json = """
        {
          "createdAt": -978307200,
          "id": "00000000-0000-0000-0000-000000000002",
          "name": "Prompt"
        }
        """

        let tag = try JSONDecoder().decode(ClipboardTag.self, from: Data(json.utf8))

        XCTAssertEqual(tag.colorHex, ClipboardTag.defaultColorHex)
    }

    func testQuickPanelDismissalModeDefaultsToMouseExit() {
        XCTAssertEqual(QuickPanelDismissalMode.defaultMode, .mouseExit)
    }

    func testQuickPanelDismissalModeRawValuesAreStableForUserDefaults() {
        XCTAssertEqual(QuickPanelDismissalMode.mouseExit.rawValue, "mouseExit")
        XCTAssertEqual(QuickPanelDismissalMode.shortcutToggle.rawValue, "shortcutToggle")
    }

    func testTextSearchIsCaseInsensitiveAndImagesDoNotMatchTextQueries() {
        let text = ClipboardHistoryItem(content: .text("FuFu coffee note"))
        let image = ClipboardHistoryItem(content: .image(ImagePayload(fileName: "image.png", pasteboardType: "public.png", byteCount: 10)))

        XCTAssertTrue(HistoryRules.matchesSearch(text, query: "COFFEE"))
        XCTAssertFalse(HistoryRules.matchesSearch(image, query: "COFFEE"))
        XCTAssertTrue(HistoryRules.matchesSearch(image, query: " "))
    }
}
