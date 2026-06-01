import Foundation

public struct ClipboardHistoryItem: Identifiable, Codable, Equatable, Sendable {
    public enum Content: Codable, Equatable, Sendable {
        case text(String)
        case image(ImagePayload)
    }

    public let id: UUID
    public var createdAt: Date
    public var isPinned: Bool
    public var tagIDs: [UUID]
    public var content: Content

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        isPinned: Bool = false,
        tagIDs: [UUID] = [],
        content: Content
    ) {
        self.id = id
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.tagIDs = tagIDs
        self.content = content
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case isPinned
        case tagIDs
        case content
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        tagIDs = try container.decodeIfPresent([UUID].self, forKey: .tagIDs) ?? []
        content = try container.decode(Content.self, forKey: .content)
    }
}

public struct ClipboardTag: Identifiable, Codable, Equatable, Sendable {
    public static let colorOptions = [
        ClipboardTagColorOption(hex: "#B8743D", name: "Caramel"),
        ClipboardTagColorOption(hex: "#D97757", name: "Coral"),
        ClipboardTagColorOption(hex: "#5D8A66", name: "Sage"),
        ClipboardTagColorOption(hex: "#5C7FA8", name: "Blue"),
        ClipboardTagColorOption(hex: "#8C6BC8", name: "Violet"),
        ClipboardTagColorOption(hex: "#C0648A", name: "Rose"),
        ClipboardTagColorOption(hex: "#C0903D", name: "Gold"),
        ClipboardTagColorOption(hex: "#6B8F9C", name: "Teal")
    ]
    public static let colorHexes = colorOptions.map(\.hex)
    public static let defaultColorHex = colorHexes[0]

    public let id: UUID
    public var name: String
    public var createdAt: Date
    public var colorHex: String

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        colorHex: String = ClipboardTag.defaultColorHex
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.colorHex = colorHex
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt
        case colorHex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? Self.defaultColorHex
    }
}

public struct ClipboardTagColorOption: Identifiable, Equatable, Sendable {
    public var id: String { hex }
    public let hex: String
    public let name: String

    public init(hex: String, name: String) {
        self.hex = hex
        self.name = name
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
            item.isPinned || !item.tagIDs.isEmpty || item.createdAt >= cutoff
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

    public static func matchesTag(_ item: ClipboardHistoryItem, selectedTagID: UUID?) -> Bool {
        guard let selectedTagID else {
            return true
        }

        return item.tagIDs.contains(selectedTagID)
    }
}
