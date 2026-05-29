import AppKit
import Combine
import PastePawCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var historyWindow: NSWindow?
    private var quickPanelController: QuickPanelController?
    private var hotKeyManager: GlobalHotKeyManager?
    private var cancellables = Set<AnyCancellable>()
    private let store = ClipboardHistoryStore.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let icon = appIcon() {
            NSApp.applicationIconImage = icon
        }

        installStatusItem()
        installQuickPanel()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [store] in
            InstallDiskImageCleanupPrompt.presentIfNeeded(store: store)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openPastePaw()
        return true
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: 20)
        statusItem = item

        if let button = item.button {
            button.image = toolbarIcon()
            button.imagePosition = .imageOnly
            button.toolTip = "PastePaw"
        }

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
    }

    private func installQuickPanel() {
        let panelController = QuickPanelController(store: store)
        quickPanelController = panelController

        let hotKeyManager = GlobalHotKeyManager { [weak self] in
            Task { @MainActor in
                self?.quickPanelController?.togglePanel()
            }
        }
        self.hotKeyManager = hotKeyManager
        hotKeyManager.register(store.quickPanelShortcut)

        store.$quickPanelShortcut
            .removeDuplicates()
            .sink { shortcut in
                hotKeyManager.register(shortcut)
            }
            .store(in: &cancellables)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(actionItem(title: store.localized(.openPastePaw), action: #selector(openPastePaw)))
        menu.addItem(NSMenuItem.separator())

        let recentItems = store.recentMenuItems
        if recentItems.isEmpty {
            let emptyItem = NSMenuItem(title: store.localized(.noClippings), action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            menu.addItem(scrollableHistoryItem(items: recentItems))
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(actionItem(title: store.localized(.settings), action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(actionItem(title: store.localized(.quit), action: #selector(quit), keyEquivalent: "q"))
    }

    private func toolbarIcon() -> NSImage {
        let candidates = [
            Bundle.main.url(forResource: "PastePawToolBarIcon", withExtension: "png"),
            Bundle.main.resourceURL?
                .appendingPathComponent("PastePaw_PastePaw.bundle")
                .appendingPathComponent("PastePawToolBarIcon.png"),
            Bundle.main.bundleURL
                .appendingPathComponent("PastePaw_PastePaw.bundle")
                .appendingPathComponent("PastePawToolBarIcon.png")
        ].compactMap { $0 }

        for url in candidates {
            if let image = NSImage(contentsOf: url) {
                image.size = NSSize(width: 30, height: 30)
                image.isTemplate = false
                return image
            }
        }

        return NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "PastePaw") ?? NSImage()
    }

    private func appIcon() -> NSImage? {
        let candidates = [
            Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
            Bundle.main.resourceURL?
                .appendingPathComponent("PastePaw_PastePaw.bundle")
                .appendingPathComponent("AppIcon.icns"),
            Bundle.main.bundleURL
                .appendingPathComponent("PastePaw_PastePaw.bundle")
                .appendingPathComponent("AppIcon.icns")
        ].compactMap { $0 }

        for url in candidates {
            if let image = NSImage(contentsOf: url) {
                image.size = NSSize(width: 1024, height: 1024)
                return image
            }
        }

        return NSImage(named: "AppIcon")
    }

    @objc private func openPastePaw() {
        store.startMonitoring()
        NSApp.activate(ignoringOtherApps: true)

        if let historyWindow {
            historyWindow.makeKeyAndOrderFront(nil)
            return
        }

        let contentView = ContentView()
            .environmentObject(store)
            .frame(minWidth: 760, minHeight: 560)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "PastePaw"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        historyWindow = window
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func actionItem(title: String, action: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func scrollableHistoryItem(items: [ClipboardHistoryItem]) -> NSMenuItem {
        let menuItem = NSMenuItem()
        let hostingView = NSHostingView(
            rootView: MenuBarHistoryListView(items: items) { [weak self] item in
                self?.store.copyToPasteboard(item)
                self?.statusItem?.menu?.cancelTracking()
            }
            .environmentObject(store)
        )
        hostingView.frame = NSRect(x: 0, y: 0, width: 292, height: min(max(CGFloat(items.count) * 58 + 42, 116), 336))
        menuItem.view = hostingView
        return menuItem
    }
}
