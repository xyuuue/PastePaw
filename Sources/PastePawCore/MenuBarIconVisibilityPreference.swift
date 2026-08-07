import Foundation

public enum MenuBarIconVisibilityPreference {
    public static let userDefaultsKey = "showMenuBarIcon"
    public static let defaultValue = true

    public static func value(in defaults: UserDefaults = .standard) -> Bool {
        guard defaults.object(forKey: userDefaultsKey) != nil else {
            return defaultValue
        }

        return defaults.bool(forKey: userDefaultsKey)
    }
}
