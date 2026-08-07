import Foundation
import XCTest
@testable import PastePawCore

final class MenuBarIconVisibilityPreferenceTests: XCTestCase {
    func testMenuBarIconVisibilityDefaultsToVisibleWhenPreferenceIsUnset() {
        let defaults = temporaryDefaults()

        XCTAssertTrue(MenuBarIconVisibilityPreference.value(in: defaults))
    }

    func testMenuBarIconVisibilityReadsSavedHiddenPreference() {
        let defaults = temporaryDefaults()
        defaults.set(false, forKey: MenuBarIconVisibilityPreference.userDefaultsKey)

        XCTAssertFalse(MenuBarIconVisibilityPreference.value(in: defaults))
    }

    private func temporaryDefaults(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UserDefaults {
        let suiteName = "PastePawTests.MenuBarIconVisibilityPreference.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create temporary UserDefaults suite", file: file, line: line)
            return .standard
        }

        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
