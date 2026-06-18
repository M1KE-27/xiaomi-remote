import SwiftUI
import UIKit

/// Háptica ligera reutilizable (preparada para mínima latencia).
enum Haptics {
    private static let gen: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .light); g.prepare(); return g
    }()
    static func tap() { gen.impactOccurred(intensity: 0.7); gen.prepare() }
}

// MARK: - Paleta
private enum Palette {
    static let bg0 = Color(red: 0.05, green: 0.05, blue: 0.06)
    static let bg1 = Color(red: 0.02, green: 0.02, blue: 0.03)
    static let body0 = Color(red: 0.20, green: 0.21, blue: 0.24)
    static let body1 = Color(red: 0.10, green: 0.10, blue: 0.12)
    static let keyHi = Color(red: 0.30, green: 0.31, blue: 0.35)
    static let keyLo = Color(red: 0.16, green: 0.16, blue: 0.19)
    static let accent = Color(red: 1.0, green: 0.55, blue: 0.0)
    static let ringLo = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let ringHi = Color(red: 0.17, green: 0.17, blue: 0.20)
}

// MARK: - Keycodes Android
private enum K {
    static let power = 26, back = 4, home = 3, mi = 82
    static let up = 19, down = 20, left = 21, right = 22, ok = 23
    static let volUp = 24, volDown = 25, mute = 164
    static let assistant = 219, input = 178, chList = 172, settings = 176, ttx = 233
    static let red = 183, green = 184, yellow = 185, blue = 186
    static func digit(_ d: Int) -> Int { 7 + d }
    static let netflix = "https://www.netflix.com/title"
    static let prime = "https://app.primevideo.com"
}

struct RemoteView: View {
    @EnvironmentObject var tv: TVState

    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.bg0, Palette.bg1], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                topRow
                numberPad
                labelRow
                appRow
                dpad
                controlRow
                colorRow
                volumeRow
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .frame(maxWidth: 340)
            .background(remoteBody)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if !tv.isConnected && !AppPreview.suppressBanner { statusBanner }
        }
    }

    private var remoteBody: some View {
        RoundedRectangle(cornerRadius: 42, style: .continuous)
            .fill(LinearGradient(colors: [Palette.body0, Palette.body1],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: 42, style: .continuous)
                    .stroke(LinearGradient(colors: [.white.opacity(0.18), .clear, .black.opacity(0.25)],
                                           startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.6), radius: 18, x: 0, y: 10)
    }

    // MARK: Filas

    private var topRow: some View {
        HStack {
            CircleKey(glyph: "power", fg: .red) { tv.pressCode(K.power) }
            Spacer()
            GoogleKey { tv.pressCode(K.assistant) }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }

    private var numberPad: some View {
        VStack(spacing: 11) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 16) {
                    ForEach(1...3, id: \.self) { col in
                        let n = row * 3 + col
                        NumberKey(n) { tv.pressCode(K.digit(n)) }
                    }
                }
            }
            HStack(spacing: 12) {
                PillKey("INPUT", small: true) { tv.pressCode(K.input) }
                NumberKey(0) { tv.pressCode(K.digit(0)) }
                PillKey("CH LIST", small: true) { tv.pressCode(K.chList) }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.black.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1))
        )
    }

    private var labelRow: some View {
        HStack(spacing: 12) {
            PillKey("SETTINGS", small: true) { tv.pressCode(K.settings) }
            PillKey("TTX", small: true) { tv.pressCode(K.ttx) }
        }
    }

    private var appRow: some View {
        HStack(spacing: 12) {
            AppPill(title: "NETFLIX", colors: [Color(red: 0.9, green: 0.1, blue: 0.13),
                                               Color(red: 0.72, green: 0.02, blue: 0.06)], heavy: true) {
                tv.launchApp(K.netflix)
            }
            AppPill(title: "prime video", colors: [Color(red: 0.10, green: 0.74, blue: 0.95),
                                                   Color(red: 0.0, green: 0.55, blue: 0.80)], heavy: false) {
                tv.launchApp(K.prime)
            }
        }
    }

    private var dpad: some View {
        ZStack {
            // Anillo rebajado
            Circle()
                .fill(RadialGradient(colors: [Palette.ringLo, Palette.ringHi],
                                     center: .center, startRadius: 30, endRadius: 120))
                .overlay(Circle().stroke(Color.black.opacity(0.5), lineWidth: 1).blur(radius: 1))
                .overlay(Circle().stroke(Color.white.opacity(0.05), lineWidth: 1))
                .frame(width: 208, height: 208)

            VStack {
                DirKey("chevron.up") { tv.pressCode(K.up) }
                Spacer()
                HStack {
                    DirKey("chevron.left") { tv.pressCode(K.left) }
                    Spacer()
                    DirKey("chevron.right") { tv.pressCode(K.right) }
                }
                Spacer()
                DirKey("chevron.down") { tv.pressCode(K.down) }
            }
            .frame(width: 188, height: 188)
            .padding(8)

            OKKey { tv.pressCode(K.ok) }
        }
        .frame(width: 208, height: 208)
        .padding(.vertical, 4)
    }

    private var controlRow: some View {
        HStack(spacing: 30) {
            CircleKey(glyph: "m.square", size: 42) { tv.pressCode(K.mi) }
            CircleKey(glyph: "arrow.left", size: 42) { tv.pressCode(K.back) }
            CircleKey(glyph: "circle", size: 42) { tv.pressCode(K.home) }
        }
    }

    private var colorRow: some View {
        HStack(spacing: 18) {
            ColorKey([Color(red: 0.95, green: 0.25, blue: 0.22), Color(red: 0.80, green: 0.12, blue: 0.10)]) { tv.pressCode(K.red) }
            ColorKey([Color(red: 0.34, green: 0.78, blue: 0.40), Color(red: 0.18, green: 0.60, blue: 0.25)]) { tv.pressCode(K.green) }
            ColorKey([Color(red: 1.0, green: 0.86, blue: 0.25), Color(red: 0.92, green: 0.72, blue: 0.05)]) { tv.pressCode(K.yellow) }
            ColorKey([Color(red: 0.27, green: 0.55, blue: 0.97), Color(red: 0.13, green: 0.40, blue: 0.85)]) { tv.pressCode(K.blue) }
        }
    }

    private var volumeRow: some View {
        HStack(spacing: 30) {
            CircleKey(glyph: "minus", size: 48) { tv.pressCode(K.volDown) }
            CircleKey(glyph: "speaker.slash.fill", size: 42) { tv.pressCode(K.mute) }
            CircleKey(glyph: "plus", size: 48) { tv.pressCode(K.volUp) }
        }
    }

    private var statusBanner: some View {
        VStack {
            HStack(spacing: 8) {
                if case .connecting = tv.client?.state {
                    ProgressView().scaleEffect(0.7).tint(.black)
                    Text("Conectando…")
                } else {
                    Image(systemName: "wifi.exclamationmark")
                    Text("Sin conexión")
                    Button("Reconectar") { tv.reconnectIfNeeded() }.font(.caption.bold())
                }
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill(Color.orange.opacity(0.95)))
            .foregroundColor(.black)
            .padding(.top, 12)
            Spacer()
        }
    }
}

// MARK: - Botón base (relieve + hundido + touch-down + háptica)

private struct Pressable<Content: View>: View {
    let action: () -> Void
    @ViewBuilder var content: (Bool) -> Content
    @State private var pressed = false

    var body: some View {
        content(pressed)
            .scaleEffect(pressed ? 0.90 : 1.0)
            .animation(.spring(response: 0.18, dampingFraction: 0.55), value: pressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !pressed { pressed = true; Haptics.tap(); action() } }
                    .onEnded { _ in pressed = false }
            )
    }
}

/// Fondo circular con relieve (luz arriba-izq, sombra abajo-der). Hundido al pulsar.
private struct RaisedCircle: View {
    let pressed: Bool
    var body: some View {
        Circle()
            .fill(LinearGradient(colors: pressed ? [Palette.keyLo, Palette.keyLo]
                                                  : [Palette.keyHi, Palette.keyLo],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Circle().stroke(Color.white.opacity(pressed ? 0.03 : 0.12), lineWidth: 1)
                        .blendMode(.overlay))
            .shadow(color: .black.opacity(pressed ? 0.0 : 0.45), radius: pressed ? 0 : 4, x: 2, y: 3)
            .shadow(color: .white.opacity(pressed ? 0.0 : 0.05), radius: 2, x: -2, y: -2)
    }
}

private struct CircleKey: View {
    let glyph: String; var fg: Color = .white; var size: CGFloat = 46; let action: () -> Void
    var body: some View {
        Pressable(action: action) { p in
            Image(systemName: glyph)
                .font(.system(size: size * 0.40, weight: .semibold))
                .foregroundColor(fg)
                .frame(width: size, height: size)
                .background(RaisedCircle(pressed: p))
        }
    }
}

private struct DirKey: View {
    let glyph: String; let action: () -> Void
    init(_ glyph: String, action: @escaping () -> Void) { self.glyph = glyph; self.action = action }
    var body: some View {
        Pressable(action: action) { p in
            Image(systemName: glyph)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white.opacity(p ? 0.6 : 0.92))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
}

private struct OKKey: View {
    let action: () -> Void
    var body: some View {
        Pressable(action: action) { p in
            Text("OK")
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(.white)
                .frame(width: 92, height: 92)
                .background(
                    Circle().fill(LinearGradient(
                        colors: p ? [Palette.keyLo, Palette.ringLo] : [Palette.keyHi, Palette.keyLo],
                        startPoint: .top, endPoint: .bottom))
                )
                .overlay(Circle().stroke(Color.white.opacity(p ? 0.05 : 0.16), lineWidth: 1))
                .shadow(color: .black.opacity(p ? 0 : 0.5), radius: p ? 0 : 6, x: 0, y: 4)
        }
    }
}

private struct NumberKey: View {
    let n: Int; let action: () -> Void
    init(_ n: Int, action: @escaping () -> Void) { self.n = n; self.action = action }
    var body: some View {
        Pressable(action: action) { p in
            Text("\(n)")
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(p ? 0.7 : 1))
                .frame(width: 50, height: 50)
                .background(RaisedCircle(pressed: p))
        }
    }
}

/// Píldora oscura con relieve (INPUT, CH LIST, SETTINGS, TTX).
private struct PillKey: View {
    let title: String; var small = false; let action: () -> Void
    init(_ title: String, small: Bool = false, action: @escaping () -> Void) {
        self.title = title; self.small = small; self.action = action
    }
    var body: some View {
        Pressable(action: action) { p in
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(p ? 0.6 : 0.92))
                .frame(maxWidth: .infinity).frame(height: 38)
                .background(
                    Capsule().fill(LinearGradient(
                        colors: p ? [Palette.keyLo, Palette.keyLo] : [Palette.keyHi, Palette.keyLo],
                        startPoint: .top, endPoint: .bottom))
                )
                .overlay(Capsule().stroke(Color.white.opacity(p ? 0.03 : 0.10), lineWidth: 1))
                .shadow(color: .black.opacity(p ? 0 : 0.4), radius: p ? 0 : 3, x: 0, y: 2)
        }
    }
}

/// Píldora de app con color de marca y degradado.
private struct AppPill: View {
    let title: String; let colors: [Color]; let heavy: Bool; let action: () -> Void
    var body: some View {
        Pressable(action: action) { p in
            Text(title)
                .font(.system(size: 14, weight: heavy ? .heavy : .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 42)
                .background(
                    Capsule().fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                )
                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                .shadow(color: colors[0].opacity(p ? 0.0 : 0.45), radius: p ? 0 : 8, x: 0, y: 4)
                .brightness(p ? -0.08 : 0)
        }
    }
}

private struct ColorKey: View {
    let colors: [Color]; let action: () -> Void
    init(_ colors: [Color], action: @escaping () -> Void) { self.colors = colors; self.action = action }
    var body: some View {
        Pressable(action: action) { p in
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                .frame(width: 46, height: 28)
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1))
                .shadow(color: colors[0].opacity(p ? 0 : 0.5), radius: p ? 0 : 5, x: 0, y: 3)
                .brightness(p ? -0.1 : 0)
        }
    }
}

private struct GoogleKey: View {
    let action: () -> Void
    private let googleGradient = AngularGradient(
        colors: [Color(red: 0.26, green: 0.52, blue: 0.96),
                 Color(red: 0.92, green: 0.26, blue: 0.21),
                 Color(red: 0.98, green: 0.74, blue: 0.02),
                 Color(red: 0.20, green: 0.66, blue: 0.33),
                 Color(red: 0.26, green: 0.52, blue: 0.96)], center: .center)
    var body: some View {
        Pressable(action: action) { p in
            ZStack {
                Circle().fill(googleGradient)
                Image(systemName: "mic.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 46, height: 46)
            .shadow(color: .black.opacity(p ? 0 : 0.4), radius: p ? 0 : 4, x: 2, y: 3)
            .brightness(p ? -0.1 : 0)
        }
    }
}

#Preview {
    RemoteView().environmentObject(TVState())
}
