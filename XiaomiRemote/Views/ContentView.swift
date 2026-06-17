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
        .tint(.orange)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $tv.showPairing) {
            PairingView()
                .environmentObject(tv)
                .interactiveDismissDisabled(true)
        }
        .onAppear {
            // Reconnect silently only if this TV is already paired; otherwise
            // send the user to settings to discover / pair.
            if !tv.tvHost.isEmpty {
                tv.connect()
                if !tv.isConnected && !tv.showPairing {
                    selectedTab = 1
                }
            } else {
                selectedTab = 1
            }
        }
    }
}
