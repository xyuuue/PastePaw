import AppKit

@MainActor
final class ClipboardMonitor {
    private let pasteboard: NSPasteboard
    private var timer: Timer?
    private var lastChangeCount: Int
    private var skippedChangeCount: Int?
    private let onChange: () -> Void

    init(pasteboard: NSPasteboard = .general, onChange: @escaping () -> Void) {
        self.pasteboard = pasteboard
        self.lastChangeCount = pasteboard.changeCount
        self.onChange = onChange
    }

    func start() {
        guard timer == nil else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func skipNextChangeCount(_ changeCount: Int) {
        skippedChangeCount = changeCount
        lastChangeCount = changeCount
    }

    private func tick() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else {
            return
        }

        lastChangeCount = currentChangeCount

        if skippedChangeCount == currentChangeCount {
            skippedChangeCount = nil
            return
        }

        onChange()
    }
}
