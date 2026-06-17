import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tv: TVState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            RemoteView()
                .tabItem {
                    Label("Remote", systemImage: "tv.remote.fill")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(1)
        }
        .tint(.white)
        .preferredColorScheme(.dark)
        .onAppear {
            if !tv.tvHost.isEmpty {
                tv.connect()
            } else {
                selectedTab = 1
            }
        }
    }
}
