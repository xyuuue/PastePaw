import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("PastePaw Icon.png")
let resources = root.appendingPathComponent("Sources/PastePaw/Resources", isDirectory: true)
let iconset = resources.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let preview = resources.appendingPathComponent("AppIconPreview.png")
let icns = resources.appendingPathComponent("AppIcon.icns")

guard FileManager.default.fileExists(atPath: source.path) else {
    throw NSError(
        domain: "PastePawIconGenerator",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Missing source icon at \(source.path)"]
    )
}

try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let variants: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

guard let sourceImage = NSImage(contentsOf: source) else {
    throw NSError(
        domain: "PastePawIconGenerator",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Could not read source icon at \(source.path)"]
    )
}

for variant in variants {
    let image = resizedImage(sourceImage, size: CGSize(width: variant.1, height: variant.1))
    try writePNG(image, to: iconset.appendingPathComponent(variant.0))
}

try writePNG(resizedImage(sourceImage, size: CGSize(width: 1024, height: 1024)), to: preview)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw NSError(domain: "PastePawIconGenerator", code: Int(process.terminationStatus))
}

func resizedImage(_ image: NSImage, size: CGSize) -> NSImage {
    let resized = NSImage(size: size)
    resized.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: CGRect(origin: .zero, size: size), from: .zero, operation: .copy, fraction: 1)
    resized.unlockFocus()
    return resized
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "PastePawIconGenerator", code: 3)
    }

    try data.write(to: url, options: .atomic)
}
