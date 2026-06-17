import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var tv: TVState
    @State private var hostInput: String = ""
    @FocusState private var hostFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Form {
                    Section("TV") {
                        HStack {
                            Image(systemName: "tv")
                                .foregroundColor(.secondary)
                            TextField("IP del TV (ej: 192.168.1.100)", text: $hostInput)
                                .keyboardType(.numbersAndPunctuation)
                                .autocorrectionDisabled()
                                .focused($hostFocused)
                                .onAppear { hostInput = tv.tvHost }
                        }
                    }

                    Section("Conexion") {
                        HStack {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 10, height: 10)
                            Text(tv.connectionStateLabel)
                                .foregroundColor(.primary)
                        }

                        Button(tv.isConnected ? "Desconectar" : "Conectar") {
                            if tv.isConnected {
                                tv.disconnect()
                            } else {
                                tv.saveHost(hostInput)
                                tv.connect()
                            }
                        }
                        .foregroundColor(tv.isConnected ? .red : .blue)
                    }

                    Section("Info") {
                        LabeledContent("Puerto", value: "6466 (Android TV Remote)")
                        LabeledContent("Protocolo", value: "TLS directo, sin intermediario")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var statusColor: Color {
        switch tv.client?.state {
        case .connected: return .green
        case .connecting: return .yellow
        case .failed: return .red
        default: return .gray
        }
    }
}
