import SwiftUI

@main
struct PPIOClaudeInstallerApp: App {
    @StateObject private var state = InstallerState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .frame(width: 600, height: 480)
        }
        .windowResizability(.contentSize)
    }
}
