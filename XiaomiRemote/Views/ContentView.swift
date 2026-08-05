import SwiftUI

public struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        TabView(selection: $appState.selectedTab) {
            RemoteView()
                .tabItem {
                    Label("Mando", systemImage: "tv.remote.fill")
                }
                .tag(0)

            DevicesView()
                .tabItem {
                    Label("Dispositivos", systemImage: "tv.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(Color(red: 0.0, green: 0.48, blue: 1.0))
        .preferredColorScheme(.dark)
        .onAppear {
            appState.reconnectIfNeeded()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                appState.endBackgroundHold()
                appState.reconnectIfNeeded()
            case .background:
                appState.beginBackgroundHold()
            default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
