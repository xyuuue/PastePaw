import Testing
@testable import PastePawCore

struct ClipboardTagRulesTests {
    @Test func normalizesTagNameWhitespace() {
        let name = ClipboardTagRules.normalizedName("  Prompt  \n")

        #expect(name == "Prompt")
    }

    @Test func acceptsKnownTagColor() {
        let colorHex = ClipboardTagRules.resolvedColorHex(
            "#5D8A66",
            fallback: ClipboardTag.defaultColorHex
        )

        #expect(colorHex == "#5D8A66")
    }

    @Test func invalidTagColorFallsBackToSuggestedColor() {
        let colorHex = ClipboardTagRules.resolvedColorHex(
            "#FFFFFF",
            fallback: "#5C7FA8"
        )

        #expect(colorHex == "#5C7FA8")
    }

    @Test func invalidFallbackUsesDefaultColor() {
        let colorHex = ClipboardTagRules.resolvedColorHex(
            nil,
            fallback: "#FFFFFF"
        )

        #expect(colorHex == ClipboardTag.defaultColorHex)
    }
}
