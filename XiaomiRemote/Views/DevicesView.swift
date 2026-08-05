import SwiftUI

public struct DevicesView: View {
    @EnvironmentObject private var appState: AppState

    public init() {}

    public var body: some View {
        ZStack {
            // Main Graphite Background #090B0F
            Color(red: 0.035, green: 0.043, blue: 0.059)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    header
                    scanControlCard
                    discoveredSection
                    manualIPSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: 500)
            }
        }
        .sheet(isPresented: $appState.showPairingSheet) {
            PairingSheetView()
                .environmentObject(appState)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Televisores")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                Text("Dispositivos detectados en tu red Wi-Fi")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Scan Control Card
    private var scanControlCard: some View {
        VStack(spacing: 12) {
            Button(action: {
                if appState.isScanning {
                    appState.stopScan()
                } else {
                    appState.startScan()
                }
            }) {
                HStack(spacing: 10) {
                    if appState.isScanning {
                        ProgressView()
                            .tint(.white)
                        Text("Buscando en red local…")
                            .font(.system(size: 15, weight: .bold))
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 18, weight: .bold))
                        Text("Buscar televisores")
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                )
                .shadow(color: Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PressedScaleButtonStyle())

            if appState.isScanning {
                Text("Asegúrate de que tu TV y tu iPhone están en la misma red Wi-Fi")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.082, green: 0.098, blue: 0.125))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    // MARK: - Discovered Devices Section
    private var discoveredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TELEVISORES ENCONTRADOS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
                .padding(.horizontal, 4)

            if appState.devices.isEmpty {
                emptyDevicesView
            } else {
                ForEach(appState.devices) { device in
                    deviceCard(device)
                }
            }
        }
    }

    private var emptyDevicesView: some View {
        VStack(spacing: 10) {
            Image(systemName: "tv.slash")
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.5))
            Text("No se encontraron televisores")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
            Text("Pulsa 'Buscar televisores' o introduce la IP manualmente abajo.")
                .font(.system(size: 12))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.082, green: 0.098, blue: 0.125))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    private func deviceCard(_ device: TVDevice) -> some View {
        let isConnected = appState.connectedDevice?.id == device.id && appState.connectionStatus.isConnected

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: device.brand.iconName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isConnected ? Color(red: 0.20, green: 0.78, blue: 0.35) : Color(red: 0.0, green: 0.48, blue: 1.0))

                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("IP: \(device.host)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                if isConnected {
                    HStack(spacing: 4) {
                        Circle().fill(Color(red: 0.20, green: 0.78, blue: 0.35)).frame(width: 6, height: 6)
                        Text("Activo")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.20, green: 0.78, blue: 0.35))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.15)))
                }
            }

            Divider().background(Color.white.opacity(0.08))

            HStack(spacing: 12) {
                if isConnected {
                    Button("Desconectar") {
                        appState.disconnect()
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)

                    Spacer()

                    Button("Olvidar") {
                        appState.forgetDevice(device)
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red)
                } else {
                    Button(action: {
                        appState.connect(to: device)
                    }) {
                        Text("Conectar")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                            )
                    }
                    .buttonStyle(PressedScaleButtonStyle())

                    Spacer()

                    Button("Olvidar") {
                        appState.forgetDevice(device)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.082, green: 0.098, blue: 0.125))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isConnected ? Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.5) : Color.white.opacity(0.08), lineWidth: isConnected ? 1.5 : 1)
                )
        )
    }

    // MARK: - Manual IP Section
    private var manualIPSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONEXIÓN POR IP MANUAL")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
                .padding(.horizontal, 4)

            HStack(spacing: 10) {
                Image(systemName: "network")
                    .foregroundColor(.gray)

                TextField("Ej: 192.168.1.100", text: $appState.manualIPInput)
                    .keyboardType(.decimalPad)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()

                Button("Conectar") {
                    appState.connectManualIP()
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                )
                .buttonStyle(PressedScaleButtonStyle())
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.082, green: 0.098, blue: 0.125))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
            )
        }
    }
}

// MARK: - Pairing Sheet View
public struct PairingSheetView: View {
    @EnvironmentObject private var appState: AppState

    public var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.043, blue: 0.059)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "tv.badge.wifi")
                    .font(.system(size: 48))
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))

                Text("Vinculación con Smart TV")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("Introduce el código de seguridad que aparece en la pantalla del televisor:")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                TextField("Código de 6 dígitos", text: $appState.pairingCode)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .keyboardType(.asciiCapable)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.08))
                    )
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)

                Button("Confirmar Código") {
                    appState.submitPairingCode()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                )
                .padding(.horizontal, 20)

                Button("Cancelar") {
                    appState.cancelPairing()
                }
                .foregroundColor(.gray)
                .font(.system(size: 14))
            }
            .padding(24)
        }
    }
}

#Preview {
    DevicesView()
        .environmentObject(AppState())
}
