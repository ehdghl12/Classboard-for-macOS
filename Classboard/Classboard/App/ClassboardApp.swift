import SwiftData
import SwiftUI

@main
struct ClassboardApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(PersistenceController.sharedModelContainer)
        }
        .commands {
            SidebarCommands()
        }
    }
}
