import SwiftUI
import UIKit

/// Háptica ligera reutilizable (preparada para mínima latencia).
enum Haptics {
    private static let gen: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        return g
    }()
    static func tap() {
        gen.impactOccurred(intensity: 0.7)
        gen.prepare()
    }
}

// MARK: - Keycodes Android usados por el mando
private enum K {
    static let power = 26, back = 4, home = 3, mi = 82
    static let up = 19, down = 20, left = 21, right = 22, ok = 23
    static let volUp = 24, volDown = 25, mute = 164
    static let assistant = 219, input = 178, chList = 172, settings = 176, ttx = 233
    static let red = 183, green = 184, yellow = 185, blue = 186
    static func digit(_ d: Int) -> Int { 7 + d }          // KEYCODE_0 = 7
    static let netflix = "https://www.netflix.com/title"
    static let prime = "https://app.primevideo.com"
}

struct RemoteView: View {
    @EnvironmentObject var tv: TVState

    private let body0 = Color(red: 0.16, green: 0.16, blue: 0.18)
    private let body1 = Color(red: 0.09, green: 0.09, blue: 0.10)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                VStack(spacing: geo.size.height * 0.012) {
                    topRow
                    numberPad
                    labelRow
                    appRow
                    dpad(size: min(geo.size.width * 0.56, 200))
                    controlRow
                    colorRow
                    volumeRow
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .frame(maxWidth: 360)
                .background(
                    RoundedRectangle(cornerRadius: 40)
                        .fill(LinearGradient(colors: [body0, body1], startPoint: .top, endPoint: .bottom))
                        .shadow(color: .black.opacity(0.5), radius: 12, y: 6)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 14)

            if !tv.isConnected && !AppPreview.suppressBanner {
                statusBanner
            }
        }
    }

    private var isConnecting: Bool {
        if case .connecting = tv.client?.state { return true }
        return false
    }

    // MARK: Filas

    private var topRow: some View {
        HStack {
            CircleKey(icon: "power", fg: .red, action: { tv.pressCode(K.power) })
            Spacer()
            GoogleKey { tv.pressCode(K.assistant) }
        }
        .padding(.horizontal, 6)
    }

    private var numberPad: some View {
        VStack(spacing: 8) {
            ForEach(0..<3) { row in
                HStack(spacing: 14) {
                    ForEach(1...3, id: \.self) { col in
                        let n = row * 3 + col
                        NumberKey(n: n) { tv.pressCode(K.digit(n)) }
                    }
                }
            }
            HStack(spacing: 14) {
                TextKey("INPUT") { tv.pressCode(K.input) }
                NumberKey(n: 0) { tv.pressCode(K.digit(0)) }
                TextKey("CH LIST") { tv.pressCode(K.chList) }
            }
        }
    }

    private var labelRow: some View {
        HStack(spacing: 14) {
            TextKey("SETTINGS") { tv.pressCode(K.settings) }
            TextKey("TTX") { tv.pressCode(K.ttx) }
        }
    }

    private var appRow: some View {
        HStack(spacing: 14) {
            PillKey(title: "NETFLIX", bg: Color(red: 0.9, green: 0.05, blue: 0.1), bold: true) {
                tv.launchApp(K.netflix)
            }
            PillKey(title: "prime video", bg: Color(red: 0.0, green: 0.66, blue: 0.88), bold: false) {
                tv.launchApp(K.prime)
            }
        }
    }

    private func dpad(size: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.06)).frame(width: size, height: size)
            VStack {
                DirKey(icon: "chevron.up") { tv.pressCode(K.up) }
                Spacer()
                HStack {
                    DirKey(icon: "chevron.left") { tv.pressCode(K.left) }
                    Spacer()
                    DirKey(icon: "chevron.right") { tv.pressCode(K.right) }
                }
                Spacer()
                DirKey(icon: "chevron.down") { tv.pressCode(K.down) }
            }
            .padding(size * 0.10)
            .frame(width: size, height: size)

            OKKey(diameter: size * 0.40) { tv.pressCode(K.ok) }
        }
        .frame(width: size, height: size)
    }

    private var controlRow: some View {
        HStack(spacing: 26) {
            CircleKey(icon: "m.square", fg: .white, action: { tv.pressCode(K.mi) })
            CircleKey(icon: "arrow.left", fg: .white, action: { tv.pressCode(K.back) })
            CircleKey(icon: "circle", fg: .white, action: { tv.pressCode(K.home) })
        }
    }

    private var colorRow: some View {
        HStack(spacing: 22) {
            ColorKey(color: .red) { tv.pressCode(K.red) }
            ColorKey(color: .green) { tv.pressCode(K.green) }
            ColorKey(color: .yellow) { tv.pressCode(K.yellow) }
            ColorKey(color: .blue) { tv.pressCode(K.blue) }
        }
    }

    private var volumeRow: some View {
        HStack(spacing: 26) {
            CircleKey(icon: "minus", fg: .white, action: { tv.pressCode(K.volDown) })
            CircleKey(icon: "speaker.slash.fill", fg: .white, size: 40, action: { tv.pressCode(K.mute) })
            CircleKey(icon: "plus", fg: .white, action: { tv.pressCode(K.volUp) })
        }
    }

    private var statusBanner: some View {
        VStack {
            HStack(spacing: 8) {
                if isConnecting {
                    ProgressView().scaleEffect(0.7).tint(.black)
                    Text("Conectando…")
                } else {
                    Image(systemName: "wifi.exclamationmark")
                    Text("Sin conexión")
                    Button("Reconectar") { tv.reconnectIfNeeded() }
                        .font(.caption.bold())
                }
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill((isConnecting ? Color.yellow : Color.orange).opacity(0.95)))
            .foregroundColor(.black)
            .padding(.top, 10)
            Spacer()
        }
        .allowsHitTesting(!isConnecting)
    }
}

// MARK: - Botón base con hundido y latencia mínima (dispara en touch-down)

private struct Pressable<Content: View>: View {
    let action: () -> Void
    @ViewBuilder var content: () -> Content
    @State private var pressed = false

    var body: some View {
        content()
            .scaleEffect(pressed ? 0.86 : 1.0)
            .brightness(pressed ? -0.12 : 0)
            .animation(.easeOut(duration: 0.07), value: pressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !pressed {                              // envía al tocar
                            pressed = true
                            Haptics.tap()
                            action()
                        }
                    }
                    .onEnded { _ in pressed = false }
            )
    }
}

// MARK: - Estilos de botón

private struct CircleKey: View {
    let icon: String
    var fg: Color = .white
    var size: CGFloat = 44
    let action: () -> Void
    var body: some View {
        Pressable(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(fg)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.white.opacity(0.12)))
        }
    }
}

private struct DirKey: View {
    let icon: String
    let action: () -> Void
    var body: some View {
        Pressable(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
    }
}

private struct OKKey: View {
    let diameter: CGFloat
    let action: () -> Void
    var body: some View {
        Pressable(action: action) {
            Text("OK")
                .font(.system(size: diameter * 0.34, weight: .bold))
                .foregroundColor(.white)
                .frame(width: diameter, height: diameter)
                .background(Circle().fill(Color.white.opacity(0.18)))
                .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
        }
    }
}

private struct NumberKey: View {
    let n: Int
    let action: () -> Void
    var body: some View {
        Pressable(action: action) {
            Text("\(n)")
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.10)))
        }
    }
}

private struct TextKey: View {
    let title: String
    let action: () -> Void
    init(_ title: String, action: @escaping () -> Void) { self.title = title; self.action = action }
    var body: some View {
        Pressable(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.10)))
        }
    }
}

private struct PillKey: View {
    let title: String
    let bg: Color
    let bold: Bool
    let action: () -> Void
    var body: some View {
        Pressable(action: action) {
            Text(title)
                .font(.system(size: 13, weight: bold ? .heavy : .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(RoundedRectangle(cornerRadius: 19).fill(bg))
        }
    }
}

private struct ColorKey: View {
    let color: Color
    let action: () -> Void
    var body: some View {
        Pressable(action: action) {
            RoundedRectangle(cornerRadius: 7)
                .fill(color)
                .frame(width: 42, height: 26)
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
    }
}

private struct GoogleKey: View {
    let action: () -> Void
    var body: some View {
        Pressable(action: action) {
            ZStack {
                Circle()
                    .fill(AngularGradient(
                        colors: [Color(red:0.26,green:0.52,blue:0.96),
                                 Color(red:0.92,green:0.26,blue:0.21),
                                 Color(red:0.98,green:0.74,blue:0.02),
                                 Color(red:0.20,green:0.66,blue:0.33),
                                 Color(red:0.26,green:0.52,blue:0.96)],
                        center: .center))
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 46, height: 46)
        }
    }
}

#Preview {
    RemoteView().environmentObject(TVState())
}
