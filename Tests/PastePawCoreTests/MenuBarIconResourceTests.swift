import Foundation
import XCTest

final class MenuBarIconResourceTests: XCTestCase {
    func testActiveMenuBarIconMatchesApprovedTemplateCandidate() throws {
        let root = repositoryRoot()
        let activeIcon = root.appendingPathComponent("Sources/PastePaw/Resources/PastePawToolBarIcon.png")
        let approvedCandidate = root.appendingPathComponent("design/icons/pastepaw-menubar-clipboard-template.png")

        XCTAssertEqual(try Data(contentsOf: activeIcon), try Data(contentsOf: approvedCandidate))
    }

    func testMenuBarIconIsRenderedAsTemplateImage() throws {
        let root = repositoryRoot()
        let appDelegate = root.appendingPathComponent("Sources/PastePaw/App/AppDelegate.swift")
        let source = try String(contentsOf: appDelegate, encoding: .utf8)

        XCTAssertTrue(source.contains("image.isTemplate = true"))
    }

    private func repositoryRoot(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> URL {
        let testsDirectory = URL(fileURLWithPath: "\(file)", isDirectory: false)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let root = testsDirectory.deletingLastPathComponent()

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: root.appendingPathComponent("Package.swift").path),
            "Could not resolve repository root",
            file: file,
            line: line
        )

        return root
    }
}
