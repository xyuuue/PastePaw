public enum ClipboardItemAccentRules {
    public static func quickPanelCardAccentColorHex(tags: [ClipboardTag]) -> String {
        guard let firstTag = tags.first else {
            return ClipboardTag.defaultColorHex
        }

        return ClipboardTagRules.resolvedColorHex(firstTag.colorHex, fallback: ClipboardTag.defaultColorHex)
    }
}
