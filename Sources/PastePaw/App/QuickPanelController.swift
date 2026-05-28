import AppKit
import SwiftUI

@MainActor
final class QuickPanelController {
    private let store: ClipboardHistoryStore
    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?

    private let expandedHeight: CGFloat = 258

    init(store: ClipboardHistoryStore) {
        self.store = store
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

        let panel = panel ?? makePanel()
        self.panel = panel
        refreshContent()
        movePanel(animated: false)
        panel.orderFrontRegardless()
    }

    func hidePanel() {
        hideTask?.cancel()
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
        let panel = NSPanel(
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
                    if isHovering {
                        self?.cancelScheduledHide()
                    } else {
                        self?.hidePanelSoon()
                    }
                },
                onClose: { [weak self] in
                    self?.hidePanel()
                }
            )
            .environmentObject(store)
        )
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
