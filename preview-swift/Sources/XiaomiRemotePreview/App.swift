import TokamakShim

@main
struct XiaomiRemotePreviewApp: App {
    var body: some Scene {
        WindowGroup("Mando Universal") {
            PreviewRoot()
        }
    }
}

/// Contenedor con un selector simple Remote / Ajustes (TabView en Tokamak es
/// limitado, así que usamos un toggle propio) sobre fondo negro tipo iPhone.
struct PreviewRoot: View {
    enum Tab { case remote, settings }
    @State private var tab: Tab = .remote
    @StateObject private var tv = MockTV()

    var body: some View {
        VStack(spacing: 0) {
            // "Marco" del teléfono
            ZStack {
                Color.black
                Group {
                    if tab == .remote {
                        RemotePreview().environmentObject(tv)
                    } else {
                        SettingsPreview().environmentObject(tv)
                    }
                }
            }
            .frame(width: 360, height: 720)
            .cornerRadius(36)

            // Barra de pestañas
            HStack(spacing: 0) {
                tabButton("📱 Remote", .remote)
                tabButton("⚙️ Ajustes", .settings)
            }
            .frame(width: 360)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.07, green: 0.07, blue: 0.08))
    }

    private func tabButton(_ title: String, _ value: Tab) -> some View {
        Button(action: { tab = value }) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(tab == value ? .orange : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
    }
}
