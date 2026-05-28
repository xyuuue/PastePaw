import AppKit
import PastePawCore

enum PasteboardReader {
    private static let imageTypes: [NSPasteboard.PasteboardType] = [
        .png,
        .tiff,
        NSPasteboard.PasteboardType("public.jpeg"),
        NSPasteboard.PasteboardType("public.heic"),
        NSPasteboard.PasteboardType("com.compuserve.gif")
    ]

    static func readCurrentItem(imagesDirectory: URL) throws -> ClipboardHistoryItem? {
        let pasteboard = NSPasteboard.general

        if let text = pasteboard.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ClipboardHistoryItem(content: .text(text))
        }

        for type in imageTypes {
            guard let data = pasteboard.data(forType: type) else {
                continue
            }

            try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)

            let fileExtension = preferredFileExtension(for: type)
            let fileName = "\(UUID().uuidString).\(fileExtension)"
            let destination = imagesDirectory.appendingPathComponent(fileName)
            try data.write(to: destination, options: .atomic)

            let image = NSImage(data: data)
            let payload = ImagePayload(
                fileName: fileName,
                pasteboardType: type.rawValue,
                byteCount: data.count,
                width: image.map { Double($0.size.width) },
                height: image.map { Double($0.size.height) }
            )

            return ClipboardHistoryItem(content: .image(payload))
        }

        return nil
    }

    static func writeToPasteboard(_ item: ClipboardHistoryItem, imagesDirectory: URL) throws -> Int {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.content {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let payload):
            let data = try Data(contentsOf: imagesDirectory.appendingPathComponent(payload.fileName))
            let type = NSPasteboard.PasteboardType(payload.pasteboardType)
            pasteboard.declareTypes([type], owner: nil)
            pasteboard.setData(data, forType: type)
        }

        return pasteboard.changeCount
    }

    private static func preferredFileExtension(for type: NSPasteboard.PasteboardType) -> String {
        switch type {
        case .png:
            return "png"
        case .tiff:
            return "tiff"
        default:
            if type.rawValue == "public.jpeg" {
                return "jpg"
            }
            if type.rawValue == "public.heic" {
                return "heic"
            }
            if type.rawValue == "com.compuserve.gif" {
                return "gif"
            }
            return "image"
        }
    }
}
