import PastePawCore
import SwiftUI

struct TagChipsView: View {
    let tags: [ClipboardTag]
    var limit = 3
    var compact = false

    var body: some View {
        if !tags.isEmpty {
            HStack(spacing: compact ? 4 : 6) {
                ForEach(Array(tags.prefix(limit))) { tag in
                    TagChipView(tag: tag, compact: compact)
                }

                if tags.count > limit {
                    Text("+\(tags.count - limit)")
                        .font(.system(size: compact ? 9 : 11, weight: .bold, design: .rounded))
                        .foregroundStyle(PastePawTheme.coffee.opacity(0.72))
                        .padding(.horizontal, compact ? 5 : 7)
                        .padding(.vertical, compact ? 2 : 4)
                        .background(PastePawTheme.warmCream.opacity(0.65), in: Capsule())
                }
            }
        }
    }
}

struct TagChipView: View {
    let tag: ClipboardTag
    var compact = false

    var body: some View {
        Label(tag.name, systemImage: "tag.fill")
            .labelStyle(.titleAndIcon)
            .font(.system(size: compact ? 9 : 11, weight: .bold, design: .rounded))
            .lineLimit(1)
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 5 : 7)
            .padding(.vertical, compact ? 2 : 4)
            .background(TagColorSwatch.color(hex: tag.colorHex), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.5), lineWidth: 1)
            )
    }
}

enum TagColorSwatch {
    static func color(hex: String) -> Color {
        let sanitized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard sanitized.count == 6, let value = UInt64(sanitized, radix: 16) else {
            return PastePawTheme.caramel
        }

        return Color(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }
}
