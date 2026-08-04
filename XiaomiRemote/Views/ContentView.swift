import SwiftUI

/// Modo preview para capturas en el Simulador (CI). Se activa solo si se lanza
/// con argumentos PREVIEW_* — no afecta al uso normal.
enum AppPreview {
    static let args = ProcessInfo.processInfo.arguments
    static var isOn: Bool { args.contains { $0.hasPrefix("PREVIEW_") } }
    static var suppressBanner: Bool { args.contains("PREVIEW_REMOTE") }
    static var initialTab: Int { args.contains("PREVIEW_SETTINGS") ? 1 : 0 }
}

struct ContentView: View {
    @EnvironmentObject var tv: TVState
    @State private var selectedTab = 0
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selectedTab) {
            RemoteView()
                .tabItem {
                    Label("Mando", systemImage: "tv.remote.fill")
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
            if AppPreview.isOn {            // capturas en CI
                selectedTab = AppPreview.initialTab
                return
            }
            // Reconnect silently only if this TV is already paired; never start
            // pairing automatically. If not paired, land on Ajustes.
            if !tv.connectIfPaired() {
                selectedTab = 1
            }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                // Volvemos a primer plano: cerrar la ventana de gracia y
                // reconectar al instante si hizo falta.
                tv.endBackgroundHold()
                tv.reconnectIfNeeded()
            case .background:
                // Pedir margen para no cortar la conexión en cambios rápidos.
                tv.beginBackgroundHold()
            default:
                break
            }
        }
    }
}
