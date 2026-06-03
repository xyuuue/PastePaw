public enum HorizontalWheelScrollMapper {
    public static func mappedOffset(
        currentOffset: Double,
        viewportWidth: Double,
        contentWidth: Double,
        horizontalDelta: Double,
        verticalDelta: Double,
        usesPreciseScrollingDeltas: Bool = true,
        wheelScrollDirection: QuickPanelWheelScrollDirection = .defaultDirection
    ) -> Double? {
        guard contentWidth > viewportWidth else {
            return nil
        }

        guard abs(verticalDelta) > abs(horizontalDelta), verticalDelta != 0 else {
            return nil
        }

        let wheelStep = usesPreciseScrollingDeltas ? verticalDelta : verticalDelta * 44
        let effectiveVerticalDelta = wheelStep * wheelScrollDirection.verticalDeltaMultiplier
        let maximumOffset = max(0, contentWidth - viewportWidth)
        return min(max(currentOffset + effectiveVerticalDelta, 0), maximumOffset)
    }
}
