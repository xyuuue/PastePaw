import Foundation

public enum ClipboardBoardNameRules {
    public static let maximumLength = 31

    public static func normalizedCustomName(_ rawName: String) -> String? {
        let trimmedName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return nil
        }

        return String(trimmedName.prefix(maximumLength))
    }
}
