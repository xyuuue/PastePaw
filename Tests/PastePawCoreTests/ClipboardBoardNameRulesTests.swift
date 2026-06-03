import Testing
@testable import PastePawCore

struct ClipboardBoardNameRulesTests {
    @Test func normalizesCustomBoardNameWhitespace() {
        let name = ClipboardBoardNameRules.normalizedCustomName("  Project Prompts  \n")

        #expect(name == "Project Prompts")
    }

    @Test func emptyCustomBoardNameResetsToDefault() {
        let name = ClipboardBoardNameRules.normalizedCustomName("   \n\t")

        #expect(name == nil)
    }

    @Test func customBoardNameIsCappedForHeaderLayout() {
        let name = ClipboardBoardNameRules.normalizedCustomName("Weekly planning clipboard for long prompt batches")

        #expect(name == "Weekly planning clipboard for l")
        #expect(name?.count == ClipboardBoardNameRules.maximumLength)
    }
}
