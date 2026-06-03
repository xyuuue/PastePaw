import AppKit

@MainActor
enum TagPrompt {
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
}
