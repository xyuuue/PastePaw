public enum HorizontalWheelScrollMapper {
    public static let preciseScrollMultiplier = 2.0
    public static let nonPreciseWheelStepMultiplier = 44.0

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

        let wheelStep = verticalDelta * (usesPreciseScrollingDeltas ? Self.preciseScrollMultiplier : Self.nonPreciseWheelStepMultiplier)
        let effectiveVerticalDelta = wheelStep * wheelScrollDirection.verticalDeltaMultiplier
        let maximumOffset = max(0, contentWidth - viewportWidth)
        return min(max(currentOffset + effectiveVerticalDelta, 0), maximumOffset)
    }
}
