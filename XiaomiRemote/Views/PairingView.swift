import SwiftUI

struct PairingView: View {
    @EnvironmentObject var tv: TVState
    @FocusState private var codeFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                animatedIcon
                content
                Spacer()
                Button("Cancelar") { tv.cancelPairing() }
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 32)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tv.pairing?.state {
        case .idle, .connecting, .handshaking, .none:
            Text("Conectando con el TV...")
                .font(.title3).foregroundColor(.white)
            ProgressView().tint(.orange)

        case .awaitingCode:
            VStack(spacing: 16) {
                Text("Introduce el código")
                    .font(.title2.bold()).foregroundColor(.white)
                Text("Mira el código que aparece en la pantalla del TV y escríbelo aquí.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                TextField("", text: $tv.pairingCode)
                    .focused($codeFocused)
                    .keyboardType(.asciiCapable)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
                    .onAppear { codeFocused = true }

                Button {
                    codeFocused = false
                    tv.submitPairingCode()
                } label: {
                    Text("Emparejar")
                        .font(.headline).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange))
                }
                .disabled(tv.pairingCode.count < 4)
            }

        case .verifying:
            Text("Verificando...").font(.title3).foregroundColor(.white)
            ProgressView().tint(.orange)

        case .paired:
            Label("¡Emparejado!", systemImage: "checkmark.circle.fill")
                .font(.title2.bold()).foregroundColor(.green)

        case .failed(let msg):
            VStack(spacing: 16) {
                Label(msg, systemImage: "exclamationmark.triangle.fill")
                    .font(.headline).foregroundColor(.red)
                    .multilineTextAlignment(.center)
                Button {
                    tv.startPairing()
                } label: {
                    Text("Reintentar")
                        .font(.headline).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange))
                }
            }
        }
    }

    private var animatedIcon: some View {
        PairingPulse(state: tv.pairing?.state ?? .connecting)
            .frame(width: 140, height: 140)
    }
}

/// Concentric pulsing rings around a TV glyph during pairing.
struct PairingPulse: View {
    let state: PairingClient.State
    @State private var animate = false

    private var color: Color {
        switch state {
        case .paired: return .green
        case .failed: return .red
        default: return .orange
        }
    }

    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(color.opacity(0.5), lineWidth: 2)
                    .scaleEffect(animate ? 1.4 : 0.5)
                    .opacity(animate ? 0 : 0.7)
                    .animation(
                        .easeOut(duration: 1.6).repeatForever(autoreverses: false).delay(Double(i) * 0.5),
                        value: animate
                    )
            }
            Image(systemName: "tv.fill")
                .font(.system(size: 46))
                .foregroundColor(color)
        }
        .onAppear { animate = true }
    }
}
