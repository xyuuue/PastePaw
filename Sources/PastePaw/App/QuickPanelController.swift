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

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .scrollWheel,
           QuickPanelHorizontalScrollBridge.handle(event, in: self, wheelScrollDirection: wheelScrollDirection) {
            return
        }

        super.sendEvent(event)
    }
}

@MainActor
private enum QuickPanelHorizontalScrollBridge {
    static func handle(
        _ event: NSEvent,
        in window: NSWindow,
        wheelScrollDirection: QuickPanelWheelScrollDirection
    ) -> Bool {
        guard let scrollView = horizontalScrollView(for: event, in: window),
              let documentView = scrollView.documentView else {
            return false
        }

        let currentOffset = Double(scrollView.contentView.bounds.origin.x)
        let viewportWidth = Double(scrollView.contentView.bounds.width)
        let contentWidth = Double(max(documentView.bounds.width, documentView.frame.width, documentView.fittingSize.width))

        guard let mappedOffset = HorizontalWheelScrollMapper.mappedOffset(
            currentOffset: currentOffset,
            viewportWidth: viewportWidth,
            contentWidth: contentWidth,
            horizontalDelta: Double(event.scrollingDeltaX),
            verticalDelta: Double(event.scrollingDeltaY),
            usesPreciseScrollingDeltas: event.hasPreciseScrollingDeltas,
            wheelScrollDirection: wheelScrollDirection
        ) else {
            return false
        }

        let targetOrigin = NSPoint(x: mappedOffset, y: scrollView.contentView.bounds.origin.y)
        if event.hasPreciseScrollingDeltas {
            scrollView.contentView.scroll(to: targetOrigin)
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.08
                context.allowsImplicitAnimation = true
                scrollView.contentView.animator().setBoundsOrigin(targetOrigin)
            }
        }
        scrollView.reflectScrolledClipView(scrollView.contentView)
        return true
    }

    private static func horizontalScrollView(for event: NSEvent, in window: NSWindow) -> NSScrollView? {
        guard let contentView = window.contentView else {
            return nil
        }

        let eventLocation = contentView.convert(event.locationInWindow, from: nil)
        guard let hitView = contentView.hitTest(eventLocation) else {
            return nil
        }

        var currentView: NSView? = hitView
        while let view = currentView {
            if let scrollView = view as? NSScrollView {
                return scrollView
            }

            currentView = view.superview
        }

        return nil
    }
}
