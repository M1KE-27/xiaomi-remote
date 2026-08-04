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
                    discoverySection
                    manualSection
                    connectionSection
                    infoSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { hostInput = tv.tvHost }
        }
    }

    // MARK: - Discovery

    private var discoverySection: some View {
        Section("Televisores Detectados") {
            Button {
                if tv.discovery.isScanning { tv.stopScan() } else { tv.startScan() }
            } label: {
                HStack(spacing: 12) {
                    RadarIcon(active: tv.discovery.isScanning)
                        .frame(width: 26, height: 26)
                    Text(tv.discovery.isScanning ? "Buscando..." : "Buscar dispositivos")
                    Spacer()
                    if tv.discovery.isScanning {
                        ProgressView().tint(.orange)
                    }
                }
            }
            .foregroundColor(.primary)

            ForEach(tv.discovery.devices) { device in
                Button {
                    hostInput = device.host
                    tv.select(device)
                } label: {
                    HStack {
                        Image(systemName: "tv.fill").foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text(device.name).foregroundColor(.primary)
                            Text(device.host).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.secondary)
                    }
                }
            }

            if tv.discovery.isScanning && tv.discovery.devices.isEmpty {
                Text("Asegúrate de que el TV está encendido y en la misma WiFi.")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Manual entry

    private var manualSection: some View {
        Section("IP manual") {
            HStack {
                Image(systemName: "network").foregroundColor(.secondary)
                TextField("IP del TV (ej: 192.168.3.17)", text: $hostInput)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
                    .focused($hostFocused)
            }
        }
    }

    // MARK: - Connection

    private var connectionSection: some View {
        Section("Conexión") {
            HStack {
                Circle().fill(statusColor).frame(width: 10, height: 10)
                Text(tv.connectionStateLabel).foregroundColor(.primary)
            }

            Button(tv.isConnected ? "Desconectar" : "Conectar / Emparejar") {
                hostFocused = false
                if tv.isConnected {
                    tv.disconnect()
                } else {
                    tv.saveHost(hostInput)
                    tv.connect()
                }
            }
            .foregroundColor(tv.isConnected ? .red : .orange)

            Button("Olvidar emparejamiento") { tv.forgetPairing() }
                .foregroundColor(.secondary)
        }
    }

    private var infoSection: some View {
        Section("Info") {
            LabeledContent("Emparejar", value: "Puerto 6467")
            LabeledContent("Control", value: "Puerto 6466")
            LabeledContent("Protocolo", value: "Android TV Remote v2")
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

/// Animated radar glyph that pulses while scanning.
struct RadarIcon: View {
    let active: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            Image(systemName: "dot.radiowaves.left.and.right")
                .foregroundColor(active ? .orange : .secondary)
            if active {
                Circle()
                    .stroke(Color.orange.opacity(0.6), lineWidth: 2)
                    .scaleEffect(pulse ? 1.8 : 0.6)
                    .opacity(pulse ? 0 : 0.8)
            }
        }
        .onChange(of: active) { now in
            pulse = false
            if now {
                withAnimation(.easeOut(duration: 1.1).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
        }
        .onAppear {
            if active {
                withAnimation(.easeOut(duration: 1.1).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
        }
    }
}
