import SwiftUI
import UIKit

struct DirectionPad: View {
    let onCommand: (RemoteCommand) -> Void
    @State private var activeDirection: RemoteCommand? = nil

    init(onCommand: @escaping (RemoteCommand) -> Void) {
        self.onCommand = onCommand
    }

    var body: some View {
        ZStack {
            // Outer Metallic D-Pad Ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.16, green: 0.18, blue: 0.22),
                            Color(red: 0.08, green: 0.09, blue: 0.11),
                            Color(red: 0.05, green: 0.06, blue: 0.07)
                        ],
                        center: .center,
                        startRadius: 25,
                        endRadius: 100
                    )
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.15), .white.opacity(0.02), .black.opacity(0.5)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.65), radius: 10, x: 0, y: 5)
                .frame(width: 190, height: 190)

            // Directional Buttons
            VStack {
                dpadButton(command: .up, icon: "chevron.up", label: "Arriba")
                Spacer()
                HStack {
                    dpadButton(command: .left, icon: "chevron.left", label: "Izquierda")
                    Spacer()
                    dpadButton(command: .right, icon: "chevron.right", label: "Derecha")
                }
                Spacer()
                dpadButton(command: .down, icon: "chevron.down", label: "Abajo")
            }
            .frame(width: 172, height: 172)

            // Central OK Button
            okButton
        }
        .frame(width: 190, height: 190)
    }

    private func dpadButton(command: RemoteCommand, icon: String, label: String) -> some View {
        Button(action: {
            triggerCommand(command)
        }) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(activeDirection == command ? Color(red: 0.0, green: 0.48, blue: 1.0) : .white.opacity(0.9))
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressedScaleButtonStyle())
        .accessibilityLabel(label)
    }

    private var okButton: some View {
        Button(action: {
            triggerCommand(.ok)
        }) {
            Text("OK")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
                .frame(width: 76, height: 76)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.25, green: 0.28, blue: 0.32),
                                    Color(red: 0.12, green: 0.13, blue: 0.15)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PressedScaleButtonStyle())
        .accessibilityLabel("Seleccionar u OK")
    }

    private func triggerCommand(_ command: RemoteCommand) {
        activeDirection = command
        onCommand(command)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if activeDirection == command {
                activeDirection = nil
            }
        }
    }
}

// MARK: - Pressed Scale Button Style
struct PressedScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .brightness(configuration.isPressed ? -0.1 : 0.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
