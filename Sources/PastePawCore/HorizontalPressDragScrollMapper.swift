public enum HorizontalPressDragScrollMapper {
    public static let minimumHorizontalDragDistance = 4.0

    public static func shouldActivate(
        horizontalTranslation: Double,
        verticalTranslation: Double,
        minimumHorizontalDragDistance: Double = Self.minimumHorizontalDragDistance
    ) -> Bool {
        let horizontalDistance = abs(horizontalTranslation)
        guard horizontalDistance >= minimumHorizontalDragDistance else {
            return false
        }

        return horizontalDistance > abs(verticalTranslation)
    }

    public static func mappedOffset(
        currentOffset: Double,
        viewportWidth: Double,
        contentWidth: Double,
        dragTranslationX: Double
    ) -> Double? {
        guard contentWidth > viewportWidth else {
            return nil
        }

        let maximumOffset = max(0, contentWidth - viewportWidth)
        return min(max(currentOffset - dragTranslationX, 0), maximumOffset)
    }
}
