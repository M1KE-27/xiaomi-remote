import SwiftUI

public struct SettingsView: View {
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
                    connectionGroup
                    feedbackGroup
                    appearanceGroup
                    diagnosticsGroup
                    appInfoGroup
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: 500)
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ajustes")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                Text("Preferencias y diagnóstico del mando")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Connection Group
    private var connectionGroup: some View {
        settingsCard(title: "CONEXIÓN") {
            Toggle(isOn: $appState.autoReconnect) {
                settingRowLabel(title: "Reconexión automática", subtitle: "Reconecta al abrir la app si está vinculada", icon: "arrow.triangle.2.circlepath")
            }
            .tint(Color(red: 0.0, green: 0.48, blue: 1.0))

            Divider().background(Color.white.opacity(0.08))

            Toggle(isOn: $appState.keepScreenAwake) {
                settingRowLabel(title: "Mantener pantalla activa", subtitle: "Evita que el iPhone apague la pantalla", icon: "sun.max.fill")
            }
            .tint(Color(red: 0.0, green: 0.48, blue: 1.0))
        }
    }

    // MARK: - Feedback Group
    private var feedbackGroup: some View {
        settingsCard(title: "FEEDBACK TÁCTIL Y SONORO") {
            Toggle(isOn: $appState.hapticFeedbackEnabled) {
                settingRowLabel(title: "Vibración (Háptica)", subtitle: "Siente una respuesta al pulsar cada botón", icon: "waveform")
            }
            .tint(Color(red: 0.0, green: 0.48, blue: 1.0))

            Divider().background(Color.white.opacity(0.08))

            Toggle(isOn: $appState.soundFeedbackEnabled) {
                settingRowLabel(title: "Sonidos", subtitle: "Emitir tono de confirmación al pulsar", icon: "speaker.wave.2.fill")
            }
            .tint(Color(red: 0.0, green: 0.48, blue: 1.0))
        }
    }

    // MARK: - Appearance Group
    private var appearanceGroup: some View {
        settingsCard(title: "APARIENCIA Y MARCA") {
            Picker(selection: $appState.selectedBrand) {
                ForEach(TVBrand.allCases) { brand in
                    Text(brand.rawValue).tag(brand)
                }
            } label: {
                settingRowLabel(title: "Marca predeterminada", subtitle: "Perfil de comandos principal", icon: "tv.fill")
            }
            .pickerStyle(.menu)
            .tint(Color(red: 0.0, green: 0.48, blue: 1.0))
        }
    }

    // MARK: - Diagnostics Group
    private var diagnosticsGroup: some View {
        settingsCard(title: "DIAGNÓSTICO DEL SISTEMA") {
            diagRow(title: "Estado de Red", value: appState.connectionStatus.statusText, valueColor: appState.connectionStatus.statusColor)
            Divider().background(Color.white.opacity(0.08))
            diagRow(title: "Televisor Seleccionado", value: appState.connectedDevice?.name ?? "Ninguno")
            Divider().background(Color.white.opacity(0.08))
            diagRow(title: "IP Configurada", value: appState.connectedDevice?.host ?? appState.manualIPInput)
            Divider().background(Color.white.opacity(0.08))
            diagRow(title: "Última Conexión", value: formattedDate(appState.lastConnectionDate))
            if let err = appState.lastError {
                Divider().background(Color.white.opacity(0.08))
                diagRow(title: "Último Error", value: err, valueColor: .red)
            }
        }
    }

    // MARK: - App Info Group
    private var appInfoGroup: some View {
        settingsCard(title: "INFORMACIÓN DE LA APP") {
            diagRow(title: "Aplicación", value: "Mando Universal")
            Divider().background(Color.white.opacity(0.08))
            diagRow(title: "Versión", value: "1.0")
            Divider().background(Color.white.opacity(0.08))
            diagRow(title: "Build", value: "1")
            Divider().background(Color.white.opacity(0.08))
            diagRow(title: "Bundle ID", value: "com.local.xiaomiremote")
        }
    }

    // MARK: - Helper Views
    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                content()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.082, green: 0.098, blue: 0.125))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
            )
        }
    }

    private func settingRowLabel(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
    }

    private func diagRow(title: String, value: String, valueColor: Color = .white) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(valueColor)
                .lineLimit(1)
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Nunca" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
