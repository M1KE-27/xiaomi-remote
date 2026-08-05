import SwiftUI
import UIKit

struct RemoteView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            // Main Graphite Background #090B0F
            Color(red: 0.035, green: 0.043, blue: 0.059)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    headerSection
                    connectedCard
                    quickActionsGrid
                    appsGrid
                    DirectionPad { cmd in
                        appState.sendCommand(cmd)
                    }
                    .padding(.vertical, 4)
                    rockersAndMuteSection
                    colorButtonsRow
                    keypadToggleSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: 500)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Mando Universal")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
                
                Text(appState.connectedDevice?.name ?? "Sin televisión conectada")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            Spacer()

            // Status Indicator Badge
            HStack(spacing: 6) {
                Circle()
                    .fill(appState.connectionStatus.statusColor)
                    .frame(width: 8, height: 8)
                Text(appState.connectionStatus.statusText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(appState.connectionStatus.statusColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(appState.connectionStatus.statusColor.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(appState.connectionStatus.statusColor.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Connected TV Card
    private var connectedCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: appState.connectedDevice?.brand.iconName ?? "tv")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(appState.connectedDevice?.name ?? "Televisor No Seleccionado")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(appState.connectedDevice?.host ?? "Toca cambiar para vincular un TV")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: {
                appState.selectedTab = 1
            }) {
                HStack(spacing: 4) {
                    Text("Cambiar")
                        .font(.system(size: 12, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.12))
                )
            }
            .buttonStyle(PressedScaleButtonStyle())
            .accessibilityLabel("Cambiar dispositivo seleccionado")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.082, green: 0.098, blue: 0.125))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Quick Actions Grid
    private var quickActionsGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: 10) {
            actionCard(title: "Encendido", icon: "power", color: .red) {
                appState.sendCommand(.power)
            }
            actionCard(title: "Fuente", icon: "tv.and.mediabox", color: .cyan) {
                appState.sendCommand(.input)
            }
            actionCard(title: "Inicio", icon: "house.fill", color: .white) {
                appState.sendCommand(.home)
            }
            actionCard(title: "Menú", icon: "line.3.horizontal", color: .white) {
                appState.sendCommand(.menu)
            }
            actionCard(title: "Atrás", icon: "arrow.uturn.backward", color: .white) {
                appState.sendCommand(.back)
            }
            actionCard(title: "Asistente", icon: "mic.fill", color: .orange) {
                appState.sendCommand(.voiceAssistant)
            }
        }
    }

    private func actionCard(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.082, green: 0.098, blue: 0.125))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PressedScaleButtonStyle())
        .accessibilityLabel(title)
    }

    // MARK: - Rockers & Mute Section
    private var rockersAndMuteSection: some View {
        HStack(spacing: 20) {
            // Volume Rocker
            VStack(spacing: 0) {
                rockerBtn(icon: "plus", label: "Subir Volumen") {
                    appState.sendCommand(.volUp)
                }
                Text("VOL")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.gray)
                    .padding(.vertical, 4)
                rockerBtn(icon: "minus", label: "Bajar Volumen") {
                    appState.sendCommand(.volDown)
                }
            }
            .frame(width: 68)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.082, green: 0.098, blue: 0.125))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
            )

            // Center Mute Button
            Button(action: {
                appState.sendCommand(.mute)
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.082, green: 0.098, blue: 0.125))
                        .frame(width: 52, height: 52)
                        .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    Image(systemName: "speaker.slash.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PressedScaleButtonStyle())
            .accessibilityLabel("Silenciar")

            // Channel Rocker
            VStack(spacing: 0) {
                rockerBtn(icon: "chevron.up", label: "Canal Siguiente") {
                    appState.sendCommand(.chUp)
                }
                Text("CH")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.gray)
                    .padding(.vertical, 4)
                rockerBtn(icon: "chevron.down", label: "Canal Anterior") {
                    appState.sendCommand(.chDown)
                }
            }
            .frame(width: 68)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(red: 0.082, green: 0.098, blue: 0.125))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
            )
        }
        .padding(.vertical, 4)
    }

    private func rockerBtn(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
        }
        .buttonStyle(PressedScaleButtonStyle())
        .accessibilityLabel(label)
    }

    // MARK: - Streaming Quick Apps
    private var appsGrid: some View {
        HStack(spacing: 8) {
            appPill(title: "NETFLIX", colors: [Color(red: 0.9, green: 0.05, blue: 0.08), Color(red: 0.65, green: 0.02, blue: 0.05)]) {
                appState.sendCommand(.netflix)
            }
            appPill(title: "prime", colors: [Color(red: 0.0, green: 0.65, blue: 0.88), Color(red: 0.0, green: 0.42, blue: 0.65)]) {
                appState.sendCommand(.prime)
            }
            appPill(title: "Disney+", colors: [Color(red: 0.07, green: 0.24, blue: 0.81), Color(red: 0.04, green: 0.14, blue: 0.50)]) {
                appState.sendCommand(.disney)
            }
            appPill(title: "YouTube", colors: [Color(red: 0.95, green: 0.0, blue: 0.0), Color(red: 0.60, green: 0.0, blue: 0.0)]) {
                appState.sendCommand(.youtube)
            }
        }
    }

    private func appPill(title: String, colors: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(PressedScaleButtonStyle())
        .accessibilityLabel("Abrir \(title)")
    }

    // MARK: - Color Buttons
    private var colorButtonsRow: some View {
        HStack(spacing: 12) {
            colorBtn(color: Color(red: 0.95, green: 0.25, blue: 0.22), label: "Botón Rojo") { appState.sendCommand(.red) }
            colorBtn(color: Color(red: 0.34, green: 0.78, blue: 0.40), label: "Botón Verde") { appState.sendCommand(.green) }
            colorBtn(color: Color(red: 1.0, green: 0.86, blue: 0.25), label: "Botón Amarillo") { appState.sendCommand(.yellow) }
            colorBtn(color: Color(red: 0.27, green: 0.55, blue: 0.97), label: "Botón Azul") { appState.sendCommand(.blue) }
        }
    }

    private func colorBtn(color: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(maxWidth: .infinity)
                .frame(height: 24)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(PressedScaleButtonStyle())
        .accessibilityLabel(label)
    }

    // MARK: - Numeric Keypad Toggle
    private var keypadToggleSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    appState.showNumericKeypad.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "circle.grid.3x3.fill")
                        .font(.system(size: 14))
                    Text(appState.showNumericKeypad ? "Ocultar teclado numérico" : "Mostrar teclado numérico")
                        .font(.system(size: 13, weight: .bold))
                    Image(systemName: appState.showNumericKeypad ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(red: 0.082, green: 0.098, blue: 0.125))
                        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
                )
            }
            .buttonStyle(PressedScaleButtonStyle())

            if appState.showNumericKeypad {
                numericKeypadGrid
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var numericKeypadGrid: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(1...3, id: \.self) { col in
                        let n = row * 3 + col
                        numBtn("\(n)") { appState.sendCommand(.digit(n)) }
                    }
                }
            }
            HStack(spacing: 12) {
                numBtn("INFO") { appState.sendCommand(.info) }
                numBtn("0") { appState.sendCommand(.digit(0)) }
                numBtn("GUIDE") { appState.sendCommand(.guide) }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.082, green: 0.098, blue: 0.125))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    private func numBtn(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: title.count == 1 ? 18 : 11, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(PressedScaleButtonStyle())
        .accessibilityLabel("Número \(title)")
    }
}

#Preview {
    RemoteView()
        .environmentObject(AppState())
}
