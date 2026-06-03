import Foundation

public enum ClipboardTagRules {
    public static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func resolvedColorHex(_ requestedColorHex: String?, fallback: String) -> String {
        if let requestedColorHex, ClipboardTag.colorHexes.contains(requestedColorHex) {
            return requestedColorHex
        }

        if ClipboardTag.colorHexes.contains(fallback) {
            return fallback
        }

        return ClipboardTag.defaultColorHex
    }
}
