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
    public var tagSortOrders: [UUID: Int]
    public var customTitle: String?
    public var content: Content

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        isPinned: Bool = false,
        tagIDs: [UUID] = [],
        tagSortOrders: [UUID: Int] = [:],
        customTitle: String? = nil,
        content: Content
    ) {
        self.id = id
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.tagIDs = tagIDs
        self.tagSortOrders = tagSortOrders
        self.customTitle = ClipboardItemTitleRules.normalizedCustomTitle(customTitle ?? "")
        self.content = content
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case isPinned
        case tagIDs
        case tagSortOrders
        case customTitle
        case content
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        tagIDs = try container.decodeIfPresent([UUID].self, forKey: .tagIDs) ?? []
        let decodedTagSortOrders = try container.decodeIfPresent([String: Int].self, forKey: .tagSortOrders) ?? [:]
        tagSortOrders = Dictionary(
            uniqueKeysWithValues: decodedTagSortOrders.compactMap { key, value in
                guard let tagID = UUID(uuidString: key) else {
                    return nil
                }

                return (tagID, value)
            }
        )
        customTitle = ClipboardItemTitleRules.normalizedCustomTitle(try container.decodeIfPresent(String.self, forKey: .customTitle) ?? "")
        content = try container.decode(Content.self, forKey: .content)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(tagIDs, forKey: .tagIDs)
        try container.encode(
            Dictionary(uniqueKeysWithValues: tagSortOrders.map { ($0.key.uuidString, $0.value) }),
            forKey: .tagSortOrders
        )
        try container.encodeIfPresent(customTitle, forKey: .customTitle)
        try container.encode(content, forKey: .content)
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

public enum ReorderPlacement: Sendable {
    case before
    case after
}

public enum ReorderRules {
    public static func placement(forLocationX locationX: Double, targetWidth: Double) -> ReorderPlacement {
        locationX <= max(targetWidth, 1) / 2 ? .before : .after
    }

    public static func reorderedIDs(
        _ ids: [UUID],
        moving sourceID: UUID,
        relativeTo targetID: UUID,
        placement: ReorderPlacement
    ) -> [UUID] {
        guard sourceID != targetID,
              ids.contains(sourceID),
              let targetIndex = ids.firstIndex(of: targetID) else {
            return ids
        }

        var reorderedIDs = ids.filter { $0 != sourceID }
        let adjustedTargetIndex = reorderedIDs.firstIndex(of: targetID) ?? targetIndex
        let insertionIndex: Int
        switch placement {
        case .before:
            insertionIndex = adjustedTargetIndex
        case .after:
            insertionIndex = adjustedTargetIndex + 1
        }

        reorderedIDs.insert(sourceID, at: min(max(insertionIndex, 0), reorderedIDs.count))
        return reorderedIDs
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

    public static func orderedItems(_ items: [ClipboardHistoryItem], selectedTagID: UUID?) -> [ClipboardHistoryItem] {
        let defaultOrderedItems = orderedItems(items)
        guard let selectedTagID else {
            return defaultOrderedItems
        }

        let fallbackRankByItemID = Dictionary(
            uniqueKeysWithValues: defaultOrderedItems.enumerated().map { offset, item in
                (item.id, offset)
            }
        )

        return items.sorted { lhs, rhs in
            let lhsOrder = lhs.tagSortOrders[selectedTagID]
            let rhsOrder = rhs.tagSortOrders[selectedTagID]

            switch (lhsOrder, rhsOrder) {
            case let (lhsOrder?, rhsOrder?) where lhsOrder != rhsOrder:
                return lhsOrder < rhsOrder
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                return (fallbackRankByItemID[lhs.id] ?? Int.max) < (fallbackRankByItemID[rhs.id] ?? Int.max)
            }
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
