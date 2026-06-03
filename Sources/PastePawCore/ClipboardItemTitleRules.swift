import Foundation

public enum ClipboardItemTitleRules {
    public static let maximumLength = 31

    public static func normalizedCustomTitle(_ rawTitle: String) -> String? {
        let trimmedTitle = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return nil
        }

        return String(trimmedTitle.prefix(maximumLength))
    }
}
