import Foundation
import Testing
@testable import PastePawCore

struct ClipboardItemTitleRulesTests {
    @Test func normalizesCustomItemTitleWhitespace() {
        let title = ClipboardItemTitleRules.normalizedCustomTitle("  Client Links  \n")

        #expect(title == "Client Links")
    }

    @Test func emptyCustomItemTitleResetsToDefault() {
        let title = ClipboardItemTitleRules.normalizedCustomTitle("   \n\t")

        #expect(title == nil)
    }

    @Test func customItemTitleIsCappedForCardHeaderLayout() {
        let title = ClipboardItemTitleRules.normalizedCustomTitle("Weekly planning clipboard for long prompt batches")

        #expect(title == "Weekly planning clipboard for l")
        #expect(title?.count == ClipboardItemTitleRules.maximumLength)
    }

    @Test func legacyItemsDecodeWithoutCustomTitle() throws {
        let id = UUID()
        let json = """
        {
          "id": "\(id.uuidString)",
          "createdAt": "2026-06-03T02:00:00Z",
          "isPinned": false,
          "tagIDs": [],
          "content": {
            "text": {
              "_0": "https://pastepaw.vercel.app/"
            }
          }
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let item = try decoder.decode(ClipboardHistoryItem.self, from: Data(json.utf8))

        #expect(item.customTitle == nil)
    }

    @Test func customTitleRoundTripsWithClipboardItem() throws {
        let item = ClipboardHistoryItem(customTitle: "Project Links", content: .text("https://pastepaw.vercel.app/"))
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ClipboardHistoryItem.self, from: data)

        #expect(decoded.customTitle == "Project Links")
    }
}
