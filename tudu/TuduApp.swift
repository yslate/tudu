import SwiftUI

@main
struct TuduApp: App {
    var body: some Scene {
        WindowGroup {
            TodoList()
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 320, height: 440)

        Settings {
            SettingsView()
        }
    }
}
