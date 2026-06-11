import AppKit
import PastePawCore
import SwiftUI

@MainActor
final class QuickPanelController {
    private let store: ClipboardHistoryStore
    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?
    private var menuTrackingObservers: [NSObjectProtocol] = []
    private var activeInteractionCount = 0

    private let expandedHeight: CGFloat = 292

    init(store: ClipboardHistoryStore) {
        self.store = store
        installMenuTrackingObservers()
    }

    func togglePanel() {
        if let panel, panel.isVisible {
            hidePanel()
            return
        }

        showPanel()
    }

    func showPanel() {
        store.startMonitoring()
        activeInteractionCount = 0

        let panel = panel ?? makePanel()
        self.panel = panel
        if let quickPanel = panel as? QuickPanelWindow {
            quickPanel.wheelScrollDirection = store.quickPanelWheelScrollDirection
            quickPanel.isReordering = false
        }
        refreshContent()
        movePanel(animated: false)
        panel.makeKeyAndOrderFront(nil)
    }

    func hidePanel() {
        hideTask?.cancel()
        activeInteractionCount = 0
        panel?.orderOut(nil)
    }

    func cancelScheduledHide() {
        hideTask?.cancel()
    }

    func hidePanelSoon() {
        hideTask?.cancel()
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            self?.hidePanel()
        }
    }

    private func makePanel() -> NSPanel {
        let panel = QuickPanelWindow(
            contentRect: NSRect(x: 0, y: 0, width: NSScreen.main?.visibleFrame.width ?? 900, height: expandedHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        return panel
    }

    private func refreshContent() {
        panel?.contentView = NSHostingView(
            rootView: QuickPanelView(
                onHoverChanged: { [weak self] isHovering in
                    self?.handleHoverChanged(isHovering)
                },
                onEditingChanged: { [weak self] isEditing in
                    if isEditing {
                        self?.beginInteractiveSession()
                    } else {
                        self?.endInteractiveSession()
                    }
                },
                onReorderingChanged: { [weak self] isReordering in
                    if let quickPanel = self?.panel as? QuickPanelWindow {
                        quickPanel.isReordering = isReordering
                    }
                },
                onClose: { [weak self] in
                    self?.hidePanel()
                }
            )
            .environmentObject(store)
        )
    }

    private func installMenuTrackingObservers() {
        let center = NotificationCenter.default
        menuTrackingObservers = [
            center.addObserver(
                forName: NSMenu.didBeginTrackingNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.beginInteractiveSession()
                }
            },
            center.addObserver(
                forName: NSMenu.didEndTrackingNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.endInteractiveSession()
                }
            }
        ]
    }

    private func handleHoverChanged(_ isHovering: Bool) {
        let decision = QuickPanelDismissalRules.decision(
            isHovering: isHovering,
            dismissalMode: store.quickPanelDismissalMode,
            activeInteractionCount: activeInteractionCount
        )

        switch decision {
        case .cancelScheduledHide:
            cancelScheduledHide()
        case .scheduleHide:
            hidePanelSoon()
        }
    }

    private func beginInteractiveSession() {
        activeInteractionCount += 1
        cancelScheduledHide()
    }

    private func endInteractiveSession() {
        activeInteractionCount = max(0, activeInteractionCount - 1)
        cancelScheduledHide()
    }

    private func movePanel(animated: Bool) {
        guard let panel else {
            return
        }

        let screen = screenForPanel()
        let visibleFrame = screen.visibleFrame
        let width = visibleFrame.width
        let height = expandedHeight
        let x = visibleFrame.minX
        let y = visibleFrame.minY + 20
        let frame = NSRect(x: x, y: y, width: width, height: height)

        panel.setFrame(frame, display: true, animate: animated)
    }

    private func screenForPanel() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        } ?? NSScreen.main ?? NSScreen.screens[0]
    }
}

@MainActor
private final class QuickPanelWindow: NSPanel {
    var wheelScrollDirection: QuickPanelWheelScrollDirection = .defaultDirection
    var isReordering = false
    private var pressDragScrollSession: QuickPanelPressDragScrollBridge.Session?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    override func sendEvent(_ event: NSEvent) {
        if QuickPanelPressDragScrollBridge.handle(event, in: self, session: &pressDragScrollSession) {
            return
        }

        if event.type == .scrollWheel,
           QuickPanelHorizontalScrollBridge.handle(event, in: self, wheelScrollDirection: wheelScrollDirection) {
            return
        }

        super.sendEvent(event)
    }
}

@MainActor
private enum QuickPanelPressDragScrollBridge {
    final class Session {
        weak var scrollView: NSScrollView?
        let startLocationInWindow: NSPoint
        let startOffset: Double
        var isActive = false

        init(scrollView: NSScrollView, startLocationInWindow: NSPoint, startOffset: Double) {
            self.scrollView = scrollView
            self.startLocationInWindow = startLocationInWindow
            self.startOffset = startOffset
        }
    }

    static func handle(_ event: NSEvent, in window: NSWindow, session: inout Session?) -> Bool {
        switch event.type {
        case .leftMouseDown:
            startSession(for: event, in: window, session: &session)
            return false
        case .leftMouseDragged:
            return handleDrag(event, session: &session)
        case .leftMouseUp:
            let wasActive = session?.isActive ?? false
            session = nil
            return wasActive
        default:
            return false
        }
    }

    private static func startSession(for event: NSEvent, in window: NSWindow, session: inout Session?) {
        guard let scrollView = QuickPanelScrollViewResolver.contentHorizontalScrollView(containing: event, in: window),
              let metrics = QuickPanelScrollMetrics.metrics(for: scrollView),
              HorizontalPressDragScrollMapper.shouldStartSession(
                isReordering: (window as? QuickPanelWindow)?.isReordering ?? false,
                contentIsScrollable: metrics.contentWidth > metrics.viewportWidth
              ) else {
            session = nil
            return
        }

        session = Session(
            scrollView: scrollView,
            startLocationInWindow: event.locationInWindow,
            startOffset: Double(scrollView.contentView.bounds.origin.x)
        )
    }

    private static func handleDrag(_ event: NSEvent, session: inout Session?) -> Bool {
        guard let dragSession = session else {
            return false
        }

        guard let scrollView = dragSession.scrollView,
              let metrics = QuickPanelScrollMetrics.metrics(for: scrollView) else {
            session = nil
            return false
        }

        let horizontalTranslation = Double(event.locationInWindow.x - dragSession.startLocationInWindow.x)
        let verticalTranslation = Double(event.locationInWindow.y - dragSession.startLocationInWindow.y)

        if !dragSession.isActive {
            dragSession.isActive = HorizontalPressDragScrollMapper.shouldActivate(
                horizontalTranslation: horizontalTranslation,
                verticalTranslation: verticalTranslation
            )

            guard dragSession.isActive else {
                return false
            }
        }

        guard let mappedOffset = HorizontalPressDragScrollMapper.mappedOffset(
            currentOffset: dragSession.startOffset,
            viewportWidth: metrics.viewportWidth,
            contentWidth: metrics.contentWidth,
            dragTranslationX: horizontalTranslation
        ) else {
            return false
        }

        QuickPanelScrollOffsetApplier.apply(horizontalOffset: mappedOffset, to: scrollView, animated: false)
        return true
    }
}

@MainActor
private enum QuickPanelHorizontalScrollBridge {
    static func handle(
        _ event: NSEvent,
        in window: NSWindow,
        wheelScrollDirection: QuickPanelWheelScrollDirection
    ) -> Bool {
        guard let scrollView = QuickPanelScrollViewResolver.contentHorizontalScrollView(in: window),
              let metrics = QuickPanelScrollMetrics.metrics(for: scrollView) else {
            return false
        }

        let currentOffset = Double(scrollView.contentView.bounds.origin.x)
        guard let mappedOffset = HorizontalWheelScrollMapper.mappedOffset(
            currentOffset: currentOffset,
            viewportWidth: metrics.viewportWidth,
            contentWidth: metrics.contentWidth,
            horizontalDelta: Double(event.scrollingDeltaX),
            verticalDelta: Double(event.scrollingDeltaY),
            usesPreciseScrollingDeltas: event.hasPreciseScrollingDeltas,
            wheelScrollDirection: wheelScrollDirection
        ) else {
            return false
        }

        QuickPanelScrollOffsetApplier.apply(
            horizontalOffset: mappedOffset,
            to: scrollView,
            animated: !event.hasPreciseScrollingDeltas
        )
        return true
    }
}

@MainActor
private enum QuickPanelScrollMetrics {
    struct Metrics {
        let viewportWidth: Double
        let contentWidth: Double
    }

    static func metrics(for scrollView: NSScrollView) -> Metrics? {
        guard let documentView = scrollView.documentView else {
            return nil
        }

        return Metrics(
            viewportWidth: Double(scrollView.contentView.bounds.width),
            contentWidth: Double(max(documentView.bounds.width, documentView.frame.width, documentView.fittingSize.width))
        )
    }
}

@MainActor
private enum QuickPanelScrollOffsetApplier {
    static func apply(horizontalOffset: Double, to scrollView: NSScrollView, animated: Bool) {
        let targetOrigin = NSPoint(x: horizontalOffset, y: scrollView.contentView.bounds.origin.y)
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.08
                context.allowsImplicitAnimation = true
                scrollView.contentView.animator().setBoundsOrigin(targetOrigin)
            }
        } else {
            scrollView.contentView.scroll(to: targetOrigin)
        }
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }
}

@MainActor
private enum QuickPanelScrollViewResolver {
    static func contentHorizontalScrollView(in window: NSWindow) -> NSScrollView? {
        guard let contentView = window.contentView else {
            return nil
        }

        return contentHorizontalScrollView(in: contentView)
    }

    static func contentHorizontalScrollView(containing event: NSEvent, in window: NSWindow) -> NSScrollView? {
        guard let contentView = window.contentView else {
            return nil
        }

        guard let contentScrollView = contentHorizontalScrollView(in: contentView) else {
            return nil
        }

        let eventLocation = contentView.convert(event.locationInWindow, from: nil)
        let scrollFrame = contentView.convert(contentScrollView.bounds, from: contentScrollView)
        return scrollFrame.contains(eventLocation) ? contentScrollView : nil
    }

    private static func contentHorizontalScrollView(in contentView: NSView) -> NSScrollView? {
        scrollViews(in: contentView)
            .filter(isHorizontallyScrollable)
            .max { lhs, rhs in
                visibleArea(of: lhs) < visibleArea(of: rhs)
            }
    }

    private static func visibleArea(of scrollView: NSScrollView) -> CGFloat {
        scrollView.visibleRect.width * scrollView.visibleRect.height
    }

    private static func scrollViews(in view: NSView) -> [NSScrollView] {
        let childScrollViews = view.subviews.flatMap { scrollViews(in: $0) }
        if let scrollView = view as? NSScrollView {
            return [scrollView] + childScrollViews
        }

        return childScrollViews
    }

    private static func isHorizontallyScrollable(_ scrollView: NSScrollView) -> Bool {
        guard let metrics = QuickPanelScrollMetrics.metrics(for: scrollView) else {
            return false
        }

        return metrics.contentWidth > metrics.viewportWidth
    }
}
