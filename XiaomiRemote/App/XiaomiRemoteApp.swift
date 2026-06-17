import SwiftUI

@main
struct XiaomiRemoteApp: App {
    @StateObject private var tvState = TVState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tvState)
        }
    }
}
