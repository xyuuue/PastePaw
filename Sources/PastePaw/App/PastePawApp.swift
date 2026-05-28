import SwiftUI

@main
struct PastePawApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ClipboardHistoryStore.shared

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(store)
                .frame(width: 420)
        }
    }
}
