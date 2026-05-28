import Foundation

public struct ClipboardHistoryItem: Identifiable, Codable, Equatable, Sendable {
    public enum Content: Codable, Equatable, Sendable {
        case text(String)
        case image(ImagePayload)
    }

    public let id: UUID
    public var createdAt: Date
    public var isPinned: Bool
    public var content: Content

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        isPinned: Bool = false,
        content: Content
    ) {
        self.id = id
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.content = content
    }
}

public struct ImagePayload: Codable, Equatable, Sendable {
    public var fileName: String
    public var pasteboardType: String
    public var byteCount: Int
    public var width: Double?
    public var height: Double?

    public init(
        fileName: String,
        pasteboardType: String,
        byteCount: Int,
        width: Double? = nil,
        height: Double? = nil
    ) {
        self.fileName = fileName
        self.pasteboardType = pasteboardType
        self.byteCount = byteCount
        self.width = width
        self.height = height
    }
}

public enum HistoryRules {
    public static func orderedItems(_ items: [ClipboardHistoryItem]) -> [ClipboardHistoryItem] {
        items.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            return lhs.createdAt > rhs.createdAt
        }
    }

    public static func retainedItems(
        _ items: [ClipboardHistoryItem],
        retentionDays: Int,
        now: Date = Date()
    ) -> [ClipboardHistoryItem] {
        let interval = TimeInterval(max(retentionDays, 1) * 24 * 60 * 60)
        let cutoff = now.addingTimeInterval(-interval)

        return items.filter { item in
            item.isPinned || item.createdAt >= cutoff
        }
    }

    public static func matchesSearch(_ item: ClipboardHistoryItem, query: String) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return true
        }

        switch item.content {
        case .text(let text):
            return text.localizedCaseInsensitiveContains(trimmedQuery)
        case .image:
            return false
        }
    }
}
