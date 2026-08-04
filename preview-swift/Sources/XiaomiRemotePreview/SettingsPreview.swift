import TokamakShim

/// Versión Tokamak de la pantalla de Ajustes (descubrimiento, IP, conexión).
struct SettingsPreview: View {
    @EnvironmentObject var tv: MockTV
    @State private var ip = "192.168.3.17"
    @State private var scanning = false

    var body: some View {
        ZStack {
            Color.black
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    section("DISPOSITIVOS") {
                        row {
                            Button(action: { scanning.toggle() }) {
                                HStack {
                                    Text(scanning ? "📡 Buscando…" : "📡 Buscar dispositivos")
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                            }
                        }
                        row {
                            HStack {
                                Text("📺 MiTV-MSSP2").foregroundColor(.white)
                                Spacer()
                                Text("192.168.3.17").font(.system(size: 12)).foregroundColor(.gray)
                            }
                        }
                    }

                    section("IP MANUAL") {
                        row { TextField("IP del TV", text: $ip).foregroundColor(.white) }
                    }

                    section("CONEXIÓN") {
                        row {
                            HStack {
                                Circle().fill(tv.connected ? Color.green : Color.gray)
                                    .frame(width: 10, height: 10)
                                Text(tv.connected ? "Conectado" : "Desconectado").foregroundColor(.white)
                            }
                        }
                        row {
                            Button(action: { tv.connected.toggle() }) {
                                Text(tv.connected ? "Desconectar" : "Conectar / Emparejar")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .padding(18)
            }
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(.gray)
            VStack(spacing: 0) { content() }
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(red: 0.11, green: 0.11, blue: 0.12)))
        }
    }

    private func row<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        content().padding(.horizontal, 14).padding(.vertical, 12)
    }
}
