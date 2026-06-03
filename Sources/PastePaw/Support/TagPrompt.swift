import AppKit
import PastePawCore

@MainActor
enum TagPrompt {
    struct TagDetails {
        let name: String
        let colorHex: String
    }

    static func requestName(
        title: String,
        placeholder: String,
        confirmTitle: String,
        cancelTitle: String,
        initialValue: String = ""
    ) -> String? {
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.placeholderString = placeholder
        field.stringValue = initialValue

        let alert = NSAlert()
        alert.messageText = title
        alert.accessoryView = field
        alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: cancelTitle)

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            return nil
        }

        return field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func requestTagDetails(
        title: String,
        namePlaceholder: String,
        colorTitle: String,
        confirmTitle: String,
        cancelTitle: String,
        initialName: String = "",
        initialColorHex: String
    ) -> TagDetails? {
        let nameField = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        nameField.placeholderString = namePlaceholder
        nameField.stringValue = initialName

        let colorPopup = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 240, height: 26), pullsDown: false)
        colorPopup.removeAllItems()
        for option in ClipboardTag.colorOptions {
            let item = NSMenuItem(title: option.name, action: nil, keyEquivalent: "")
            item.representedObject = option.hex
            item.image = swatchImage(hex: option.hex)
            colorPopup.menu?.addItem(item)
        }

        let selectedColorHex = ClipboardTagRules.resolvedColorHex(initialColorHex, fallback: ClipboardTag.defaultColorHex)
        if let index = ClipboardTag.colorOptions.firstIndex(where: { $0.hex == selectedColorHex }) {
            colorPopup.selectItem(at: index)
        }

        let nameStack = labeledControl(title: namePlaceholder, control: nameField)
        let colorStack = labeledControl(title: colorTitle, control: colorPopup)
        let stack = NSStackView(views: [nameStack, colorStack])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.frame = NSRect(x: 0, y: 0, width: 260, height: 78)

        let alert = NSAlert()
        alert.messageText = title
        alert.accessoryView = stack
        alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: cancelTitle)
        alert.window.initialFirstResponder = nameField

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            return nil
        }

        let selectedItem = colorPopup.selectedItem
        let colorHex = selectedItem?.representedObject as? String ?? ClipboardTag.defaultColorHex
        return TagDetails(
            name: ClipboardTagRules.normalizedName(nameField.stringValue),
            colorHex: ClipboardTagRules.resolvedColorHex(colorHex, fallback: selectedColorHex)
        )
    }

    private static func labeledControl(title: String, control: NSView) -> NSStackView {
        let label = NSTextField(labelWithString: title)
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabelColor
        label.frame = NSRect(x: 0, y: 0, width: 64, height: 20)

        let stack = NSStackView(views: [label, control])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 8
        stack.frame = NSRect(x: 0, y: 0, width: 260, height: 28)
        return stack
    }

    private static func swatchImage(hex: String) -> NSImage {
        let image = NSImage(size: NSSize(width: 14, height: 14))
        image.lockFocus()

        let rect = NSRect(x: 1, y: 1, width: 12, height: 12)
        color(hex: hex).setFill()
        NSBezierPath(ovalIn: rect).fill()
        NSColor.white.withAlphaComponent(0.72).setStroke()
        NSBezierPath(ovalIn: rect).stroke()

        image.unlockFocus()
        return image
    }

    private static func color(hex: String) -> NSColor {
        let sanitized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard sanitized.count == 6, let value = UInt64(sanitized, radix: 16) else {
            return .systemBrown
        }

        return NSColor(
            red: CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >> 8) & 0xFF) / 255.0,
            blue: CGFloat(value & 0xFF) / 255.0,
            alpha: 1
        )
    }
}
