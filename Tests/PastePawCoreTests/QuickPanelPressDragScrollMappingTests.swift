import Testing
@testable import PastePawCore

struct QuickPanelPressDragScrollMappingTests {
    @Test func horizontalPressDragActivatesDragScrollingWithoutLongPressDelay() {
        let activates = HorizontalPressDragScrollMapper.shouldActivate(
            horizontalTranslation: -12,
            verticalTranslation: 2
        )

        #expect(activates)
    }

    @Test func tinyHorizontalDragDoesNotActivateScrolling() {
        let activates = HorizontalPressDragScrollMapper.shouldActivate(
            horizontalTranslation: -2,
            verticalTranslation: 1
        )

        #expect(!activates)
    }

    @Test func verticalDominantDragDoesNotActivateHorizontalScrolling() {
        let activates = HorizontalPressDragScrollMapper.shouldActivate(
            horizontalTranslation: 9,
            verticalTranslation: 18
        )

        #expect(!activates)
    }

    @Test func leftMouseDragMovesContentRight() {
        let offset = HorizontalPressDragScrollMapper.mappedOffset(
            currentOffset: 120,
            viewportWidth: 300,
            contentWidth: 900,
            dragTranslationX: -48
        )

        #expect(offset == 168)
    }

    @Test func rightMouseDragMovesContentLeft() {
        let offset = HorizontalPressDragScrollMapper.mappedOffset(
            currentOffset: 120,
            viewportWidth: 300,
            contentWidth: 900,
            dragTranslationX: 48
        )

        #expect(offset == 72)
    }

    @Test func dragOffsetClampsToScrollableBounds() {
        let leadingOffset = HorizontalPressDragScrollMapper.mappedOffset(
            currentOffset: 8,
            viewportWidth: 300,
            contentWidth: 900,
            dragTranslationX: 48
        )
        let trailingOffset = HorizontalPressDragScrollMapper.mappedOffset(
            currentOffset: 580,
            viewportWidth: 300,
            contentWidth: 900,
            dragTranslationX: -48
        )

        #expect(leadingOffset == 0)
        #expect(trailingOffset == 600)
    }

    @Test func nonScrollableContentDoesNotMapDragOffset() {
        let offset = HorizontalPressDragScrollMapper.mappedOffset(
            currentOffset: 0,
            viewportWidth: 900,
            contentWidth: 300,
            dragTranslationX: -48
        )

        #expect(offset == nil)
    }
}
