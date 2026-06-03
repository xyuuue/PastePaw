import Testing
@testable import PastePawCore

struct QuickPanelScrollMappingTests {
    @Test func verticalWheelDeltaMovesHorizontalOffset() {
        let offset = HorizontalWheelScrollMapper.mappedOffset(
            currentOffset: 120,
            viewportWidth: 300,
            contentWidth: 900,
            horizontalDelta: 0,
            verticalDelta: 48
        )

        #expect(offset == 168)
    }

    @Test func nonPreciseMouseWheelDeltaUsesLargerHorizontalStep() {
        let offset = HorizontalWheelScrollMapper.mappedOffset(
            currentOffset: 120,
            viewportWidth: 300,
            contentWidth: 900,
            horizontalDelta: 0,
            verticalDelta: 3,
            usesPreciseScrollingDeltas: false
        )

        #expect(offset == 252)
    }

    @Test func verticalWheelDeltaClampsToScrollableBounds() {
        let leadingOffset = HorizontalWheelScrollMapper.mappedOffset(
            currentOffset: 8,
            viewportWidth: 300,
            contentWidth: 900,
            horizontalDelta: 0,
            verticalDelta: -48
        )
        let trailingOffset = HorizontalWheelScrollMapper.mappedOffset(
            currentOffset: 580,
            viewportWidth: 300,
            contentWidth: 900,
            horizontalDelta: 0,
            verticalDelta: 48
        )

        #expect(leadingOffset == 0)
        #expect(trailingOffset == 600)
    }

    @Test func existingHorizontalScrollIsNotRemapped() {
        let offset = HorizontalWheelScrollMapper.mappedOffset(
            currentOffset: 120,
            viewportWidth: 300,
            contentWidth: 900,
            horizontalDelta: 64,
            verticalDelta: 12
        )

        #expect(offset == nil)
    }

    @Test func nonScrollableContentIsNotRemapped() {
        let offset = HorizontalWheelScrollMapper.mappedOffset(
            currentOffset: 0,
            viewportWidth: 900,
            contentWidth: 300,
            horizontalDelta: 0,
            verticalDelta: 48
        )

        #expect(offset == nil)
    }
}
