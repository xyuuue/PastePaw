import AppKit
import Foundation

@MainActor
enum InstallDiskImageCleanupPrompt {
    private static let promptedVersionKey = "installDiskImageCleanupPromptedVersion"
    private static let appName = "PastePaw"
    private static let dmgName = "PastePaw.dmg"

    struct MountedDiskImage: Equatable {
        let imageURL: URL
        let mountPointURL: URL
    }

    static func presentIfNeeded(store: ClipboardHistoryStore) {
        guard isRunningFromApplications else {
            return
        }

        let promptVersion = currentPromptVersion
        guard UserDefaults.standard.string(forKey: promptedVersionKey) != promptVersion else {
            return
        }

        guard let diskImage = mountedPastePawDiskImage() else {
            return
        }

        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = store.localized(.installCleanupTitle)
        alert.informativeText = store.localized(.installCleanupMessage)
        alert.alertStyle = .informational
        alert.addButton(withTitle: store.localized(.installCleanupMoveToTrash))
        alert.addButton(withTitle: store.localized(.installCleanupKeep))

        let response = alert.runModal()
        UserDefaults.standard.set(promptVersion, forKey: promptedVersionKey)

        guard response == .alertFirstButtonReturn else {
            return
        }

        do {
            try moveToTrash(diskImage)
        } catch {
            showCleanupFailure(error, store: store)
        }
    }

    private static var currentPromptVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(version)-\(build)"
    }

    private static var isRunningFromApplications: Bool {
        let appURL = Bundle.main.bundleURL.standardizedFileURL
        let fileManager = FileManager.default
        let applicationDirectories = [
            fileManager.urls(for: .applicationDirectory, in: .localDomainMask).first,
            fileManager.urls(for: .applicationDirectory, in: .userDomainMask).first
        ].compactMap { $0?.standardizedFileURL }

        return applicationDirectories.contains { directory in
            appURL.path == directory.appendingPathComponent("\(appName).app").path
                || appURL.path.hasPrefix(directory.path + "/")
        }
    }

    private static func mountedPastePawDiskImage() -> MountedDiskImage? {
        guard let data = try? runHdiutil(arguments: ["info", "-plist"]),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let root = plist as? [String: Any],
              let images = root["images"] as? [[String: Any]] else {
            return nil
        }

        return mountedPastePawDiskImage(in: images)
    }

    static func mountedPastePawDiskImage(in images: [[String: Any]]) -> MountedDiskImage? {
        for image in images {
            guard let imagePath = image["image-path"] as? String else {
                continue
            }

            let imageURL = URL(fileURLWithPath: imagePath).standardizedFileURL
            guard imageURL.lastPathComponent == dmgName,
                  let entities = image["system-entities"] as? [[String: Any]] else {
                continue
            }

            for entity in entities {
                guard let mountPoint = entity["mount-point"] as? String else {
                    continue
                }

                let mountPointURL = URL(fileURLWithPath: mountPoint).standardizedFileURL
                let mountedAppURL = mountPointURL.appendingPathComponent("\(appName).app")
                if FileManager.default.fileExists(atPath: mountedAppURL.path) {
                    return MountedDiskImage(imageURL: imageURL, mountPointURL: mountPointURL)
                }
            }
        }

        return nil
    }

    private static func moveToTrash(_ diskImage: MountedDiskImage) throws {
        _ = try runHdiutil(arguments: ["detach", diskImage.mountPointURL.path])
        var resultingItemURL: NSURL?
        try FileManager.default.trashItem(
            at: diskImage.imageURL,
            resultingItemURL: &resultingItemURL
        )
    }

    private static func runHdiutil(arguments: [String]) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if process.terminationStatus == 0 {
            return outputData
        }

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorMessage = String(data: errorData, encoding: .utf8) ?? "hdiutil failed"
        throw NSError(
            domain: "PastePaw.InstallDiskImageCleanup",
            code: Int(process.terminationStatus),
            userInfo: [NSLocalizedDescriptionKey: errorMessage.trimmingCharacters(in: .whitespacesAndNewlines)]
        )
    }

    private static func showCleanupFailure(_ error: Error, store: ClipboardHistoryStore) {
        let alert = NSAlert()
        alert.messageText = store.localized(.installCleanupFailureTitle)
        alert.informativeText = String(
            format: store.localized(.installCleanupFailureMessage),
            error.localizedDescription
        )
        alert.alertStyle = .warning
        alert.addButton(withTitle: store.localized(.installCleanupKeep))
        alert.runModal()
    }
}
