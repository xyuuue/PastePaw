import AppKit
import SwiftUI

struct ShortcutRecorderView: View {
    @EnvironmentObject private var store: ClipboardHistoryStore
    @Binding var shortcut: PastePawKeyboardShortcut
    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 10) {
            Button {
                isRecording = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isRecording ? "keyboard.badge.ellipsis" : "keyboard")
                    Text(isRecording ? store.localized(.pressShortcut) : shortcut.displayText)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .frame(minWidth: 150)
            }
            .buttonStyle(.borderedProminent)
            .tint(isRecording ? PastePawTheme.blush : PastePawTheme.caramel)
            .background {
                if isRecording {
                    ShortcutCaptureView { newShortcut in
                        if let newShortcut {
                            shortcut = newShortcut
                        }

                        isRecording = false
                    }
                    .frame(width: 0, height: 0)
                }
            }

            Button {
                store.resetQuickPanelShortcut()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .help(store.localized(.resetShortcut))
        }
    }
}

private struct ShortcutCaptureView: NSViewRepresentable {
    let onComplete: (PastePawKeyboardShortcut?) -> Void

    func makeNSView(context: Context) -> CaptureView {
        let view = CaptureView()
        view.onComplete = onComplete

        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }

        return view
    }

    func updateNSView(_ nsView: CaptureView, context: Context) {
        nsView.onComplete = onComplete

        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    final class CaptureView: NSView {
        var onComplete: ((PastePawKeyboardShortcut?) -> Void)?

        override var acceptsFirstResponder: Bool {
            true
        }

        override func keyDown(with event: NSEvent) {
            if event.keyCode == 53 {
                onComplete?(nil)
                return
            }

            if let shortcut = PastePawKeyboardShortcut(event: event) {
                onComplete?(shortcut)
            } else {
                NSSound.beep()
            }
        }
    }
}
