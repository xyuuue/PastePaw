public enum HorizontalWheelScrollMapper {
    public static func mappedOffset(
        currentOffset: Double,
        viewportWidth: Double,
        contentWidth: Double,
        horizontalDelta: Double,
        verticalDelta: Double
    ) -> Double? {
        guard contentWidth > viewportWidth else {
            return nil
        }

        guard abs(verticalDelta) > abs(horizontalDelta), verticalDelta != 0 else {
            return nil
        }

        let maximumOffset = max(0, contentWidth - viewportWidth)
        return min(max(currentOffset + verticalDelta, 0), maximumOffset)
    }
}
