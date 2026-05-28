import AppKit
import Carbon
import Foundation

struct PastePawKeyboardShortcut: Codable, Equatable, Sendable {
    var keyCode: UInt32
    var carbonModifiers: UInt32

    static let defaultQuickPanel = PastePawKeyboardShortcut(
        keyCode: 49,
        carbonModifiers: UInt32(optionKey)
    )

    var displayText: String {
        "\(modifierSymbols)\(keyName)"
    }

    var isUsable: Bool {
        carbonModifiers.intersection(with: Self.requiredModifierMask) != 0
    }

    init(keyCode: UInt32, carbonModifiers: UInt32) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
    }

    init?(event: NSEvent) {
        let shortcut = PastePawKeyboardShortcut(
            keyCode: UInt32(event.keyCode),
            carbonModifiers: Self.carbonModifiers(from: event.modifierFlags)
        )

        guard shortcut.isUsable else {
            return nil
        }

        self = shortcut
    }

    private var modifierSymbols: String {
        var symbols = ""

        if carbonModifiers & UInt32(controlKey) != 0 {
            symbols += "^"
        }

        if carbonModifiers & UInt32(optionKey) != 0 {
            symbols += "⌥"
        }

        if carbonModifiers & UInt32(shiftKey) != 0 {
            symbols += "⇧"
        }

        if carbonModifiers & UInt32(cmdKey) != 0 {
            symbols += "⌘"
        }

        return symbols
    }

    private var keyName: String {
        switch keyCode {
        case 0: "A"
        case 1: "S"
        case 2: "D"
        case 3: "F"
        case 4: "H"
        case 5: "G"
        case 6: "Z"
        case 7: "X"
        case 8: "C"
        case 9: "V"
        case 11: "B"
        case 12: "Q"
        case 13: "W"
        case 14: "E"
        case 15: "R"
        case 16: "Y"
        case 17: "T"
        case 18: "1"
        case 19: "2"
        case 20: "3"
        case 21: "4"
        case 22: "6"
        case 23: "5"
        case 24: "="
        case 25: "9"
        case 26: "7"
        case 27: "-"
        case 28: "8"
        case 29: "0"
        case 31: "O"
        case 32: "U"
        case 34: "I"
        case 35: "P"
        case 37: "L"
        case 38: "J"
        case 40: "K"
        case 45: "N"
        case 46: "M"
        case 49: "Space"
        case 53: "Esc"
        case 123: "←"
        case 124: "→"
        case 125: "↓"
        case 126: "↑"
        default: "Key \(keyCode)"
        }
    }

    private static let requiredModifierMask = UInt32(cmdKey | optionKey | controlKey | shiftKey)

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        let normalized = flags.intersection(.deviceIndependentFlagsMask)

        if normalized.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }

        if normalized.contains(.option) {
            modifiers |= UInt32(optionKey)
        }

        if normalized.contains(.control) {
            modifiers |= UInt32(controlKey)
        }

        if normalized.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }

        return modifiers
    }
}

private extension UInt32 {
    func intersection(with mask: UInt32) -> UInt32 {
        self & mask
    }
}
