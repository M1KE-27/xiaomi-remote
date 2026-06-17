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
            // Reconnect silently only if this TV is already paired; never start
            // pairing automatically. If not paired, land on Ajustes.
            if !tv.connectIfPaired() {
                selectedTab = 1
            }
        }
    }
}
