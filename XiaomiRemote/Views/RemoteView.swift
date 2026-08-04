import SwiftUI
import UIKit

/// Háptica ligera reutilizable (preparada para mínima latencia).
enum Haptics {
    private static let gen: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .light); g.prepare(); return g
    }()
    static func tap() { gen.impactOccurred(intensity: 0.7); gen.prepare() }
}

// MARK: - Paleta de Mando Universal Realista
private enum Palette {
    static let bg0 = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let bg1 = Color(red: 0.02, green: 0.02, blue: 0.03)
    
    // Cuerpo metálico / cepillado
    static let bodyTop = Color(red: 0.18, green: 0.19, blue: 0.22)
    static let bodyMid = Color(red: 0.12, green: 0.13, blue: 0.15)
    static let bodyBot = Color(red: 0.07, green: 0.08, blue: 0.09)
    
    // Teclas 3D
    static let keyHi = Color(red: 0.25, green: 0.27, blue: 0.30)
    static let keyLo = Color(red: 0.13, green: 0.14, blue: 0.16)
    
    // Acentos
    static let accent = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let powerRed0 = Color(red: 0.88, green: 0.18, blue: 0.18)
    static let powerRed1 = Color(red: 0.55, green: 0.05, blue: 0.05)
    
    // Ring D-Pad
    static let ringLo = Color(red: 0.08, green: 0.09, blue: 0.10)
    static let ringHi = Color(red: 0.18, green: 0.19, blue: 0.22)
}

// MARK: - Keycodes Universal Android TV
private enum K {
    static let power = 26, back = 4, home = 3, menu = 82
    static let up = 19, down = 20, left = 21, right = 22, ok = 23
    static let volUp = 24, volDown = 25, mute = 164
    static let chUp = 166, chDown = 167
    static let assistant = 219, input = 178, chList = 172, settings = 176, ttx = 233
    static let red = 183, green = 184, yellow = 185, blue = 186
    static func digit(_ d: Int) -> Int { 7 + d }
    static let netflix = "https://www.netflix.com/title"
    static let prime = "https://app.primevideo.com"
}

struct RemoteView: View {
    @EnvironmentObject var tv: TVState
    @State private var selectedBrand = "SAMSUNG"

    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.bg0, Palette.bg1], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    headerEmisor
                    brandSelector
                    topActionRow
                    appsBar
                    dpad
                    navigationRow
                    rockersSection
                    colorRow
                    numberPad
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: 340)
                .background(remoteShell)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            if !tv.isConnected && !AppPreview.suppressBanner { statusBanner }
        }
    }

    private var remoteShell: some View {
        RoundedRectangle(cornerRadius: 38, style: .continuous)
            .fill(LinearGradient(colors: [Palette.bodyTop, Palette.bodyMid, Palette.bodyBot],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: 38, style: .continuous)
                    .stroke(LinearGradient(colors: [.white.opacity(0.20), .white.opacity(0.04), .black.opacity(0.4)],
                                           startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.75), radius: 20, x: 0, y: 12)
    }

    // MARK: - Componentes del Mando Realista

    private var headerEmisor: some View {
        HStack {
            Circle()
                .fill(tv.isConnected ? Color.cyan : Color(white: 0.2))
                .frame(width: 8, height: 8)
                .shadow(color: tv.isConnected ? Color.cyan.opacity(0.8) : .clear, radius: 4)
            Spacer()
            Text("MANDO UNIVERSAL")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.white.opacity(0.4))
                .tracking(2)
            Spacer()
            Circle().fill(Color.clear).frame(width: 8, height: 8)
        }
        .padding(.horizontal, 8)
    }

    private var brandSelector: some View {
        HStack(spacing: 4) {
            ForEach(["SAMSUNG", "LG", "SONY", "ANDROID"], id: \.self) { brand in
                Button(action: {
                    Haptics.tap()
                    selectedBrand = brand
                }) {
                    Text(brand)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(selectedBrand == brand ? Palette.accent : Color.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedBrand == brand ? Color.white.opacity(0.12) : Color.black.opacity(0.2))
                        )
                }
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.3)))
    }

    private var topActionRow: some View {
        HStack(spacing: 12) {
            PowerButton { tv.pressCode(K.power) }
            TactileKey("INPUT 📺") { tv.pressCode(K.input) }
            TactileKey("GEAR ⚙️") { tv.pressCode(K.settings) }
            GoogleVoiceKey { tv.pressCode(K.assistant) }
        }
    }

    private var appsBar: some View {
        HStack(spacing: 8) {
            AppPill(title: "NETFLIX", colors: [Color(red: 0.9, green: 0.05, blue: 0.08), Color(red: 0.65, green: 0.02, blue: 0.05)]) {
                tv.launchApp(K.netflix)
            }
            AppPill(title: "prime", colors: [Color(red: 0.0, green: 0.65, blue: 0.88), Color(red: 0.0, green: 0.42, blue: 0.65)]) {
                tv.launchApp(K.prime)
            }
            AppPill(title: "Disney+", colors: [Color(red: 0.07, green: 0.24, blue: 0.81), Color(red: 0.04, green: 0.14, blue: 0.50)]) {
                tv.pressCode(K.input)
            }
            AppPill(title: "YouTube", colors: [Color(red: 0.95, green: 0.0, blue: 0.0), Color(red: 0.60, green: 0.0, blue: 0.0)]) {
                tv.pressCode(K.input)
            }
        }
    }

    private var dpad: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Palette.ringLo, Palette.ringHi],
                                     center: .center, startRadius: 28, endRadius: 100))
                .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
                .shadow(color: .black.opacity(0.6), radius: 10, x: 0, y: 5)
                .frame(width: 186, height: 184)

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
            .frame(width: 168, height: 168)

            OKKey { tv.pressCode(K.ok) }
        }
        .frame(width: 186, height: 184)
    }

    private var navigationRow: some View {
        HStack(spacing: 24) {
            CircleKey(glyph: "arrow.uturn.backward", size: 44) { tv.pressCode(K.back) }
            CircleKey(glyph: "house.fill", size: 44) { tv.pressCode(K.home) }
            CircleKey(glyph: "line.3.horizontal", size: 44) { tv.pressCode(K.menu) }
        }
    }

    private var rockersSection: some View {
        HStack(spacing: 16) {
            // Rocker Volumen
            VStack(spacing: 0) {
                RockerBtn("plus") { tv.pressCode(K.volUp) }
                Text("VOL").font(.system(size: 9, weight: .bold)).foregroundColor(.gray).padding(.vertical, 2)
                RockerBtn("minus") { tv.pressCode(K.volDown) }
            }
            .frame(width: 58)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.35)))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))

            // Botón Mute
            CircleKey(glyph: "speaker.slash.fill", size: 44) { tv.pressCode(K.mute) }

            // Rocker Canales
            VStack(spacing: 0) {
                RockerBtn("chevron.up") { tv.pressCode(K.chUp) }
                Text("CH").font(.system(size: 9, weight: .bold)).foregroundColor(.gray).padding(.vertical, 2)
                RockerBtn("chevron.down") { tv.pressCode(K.chDown) }
            }
            .frame(width: 58)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.35)))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .padding(.vertical, 4)
    }

    private var colorRow: some View {
        HStack(spacing: 14) {
            ColorKey([Color(red: 0.95, green: 0.25, blue: 0.22), Color(red: 0.80, green: 0.12, blue: 0.10)]) { tv.pressCode(K.red) }
            ColorKey([Color(red: 0.34, green: 0.78, blue: 0.40), Color(red: 0.18, green: 0.60, blue: 0.25)]) { tv.pressCode(K.green) }
            ColorKey([Color(red: 1.0, green: 0.86, blue: 0.25), Color(red: 0.92, green: 0.72, blue: 0.05)]) { tv.pressCode(K.yellow) }
            ColorKey([Color(red: 0.27, green: 0.55, blue: 0.97), Color(red: 0.13, green: 0.40, blue: 0.85)]) { tv.pressCode(K.blue) }
        }
    }

    private var numberPad: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(1...3, id: \.self) { col in
                        let n = row * 3 + col
                        NumberKey(n) { tv.pressCode(K.digit(n)) }
                    }
                }
            }
            HStack(spacing: 12) {
                TactileKey("INFO", small: true) { tv.pressCode(K.ttx) }
                NumberKey(0) { tv.pressCode(K.digit(0)) }
                TactileKey("GUIDE", small: true) { tv.pressCode(K.chList) }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.25))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1))
        )
    }

    private var statusBanner: some View {
        VStack {
            HStack(spacing: 8) {
                if case .connecting = tv.client?.state {
                    ProgressView().scaleEffect(0.7).tint(.black)
                    Text("Conectando con Smart TV…")
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

// MARK: - Teclas 3D y Relieves

private struct Pressable<Content: View>: View {
    let action: () -> Void
    @ViewBuilder var content: (Bool) -> Content
    @State private var pressed = false

    var body: some View {
        content(pressed)
            .scaleEffect(pressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.16, dampingFraction: 0.6), value: pressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if !pressed { pressed = true; Haptics.tap(); action() } }
                    .onEnded { _ in pressed = false }
            )
    }
}

private struct RaisedCircle: View {
    let pressed: Bool
    var body: some View {
        Circle()
            .fill(LinearGradient(colors: pressed ? [Palette.keyLo, Palette.keyLo]
                                                  : [Palette.keyHi, Palette.keyLo],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Circle().stroke(Color.white.opacity(pressed ? 0.02 : 0.14), lineWidth: 1))
            .shadow(color: .black.opacity(pressed ? 0.1 : 0.5), radius: pressed ? 1 : 4, x: 1, y: 3)
    }
}

private struct PowerButton: View {
    let action: () -> Void
    var body: some View {
        Pressable(action: action) { p in
            Image(systemName: "power")
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle().fill(LinearGradient(colors: [Palette.powerRed0, Palette.powerRed1], startPoint: .top, endPoint: .bottom))
                )
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                .shadow(color: Palette.powerRed0.opacity(p ? 0.2 : 0.6), radius: p ? 2 : 8, x: 0, y: 4)
        }
    }
}

private struct GoogleVoiceKey: View {
    let action: () -> Void
    private let grad = AngularGradient(
        colors: [Color(red: 0.26, green: 0.52, blue: 0.96),
                 Color(red: 0.92, green: 0.26, blue: 0.21),
                 Color(red: 0.98, green: 0.74, blue: 0.02),
                 Color(red: 0.20, green: 0.66, blue: 0.33),
                 Color(red: 0.26, green: 0.52, blue: 0.96)], center: .center)
    var body: some View {
        Pressable(action: action) { p in
            ZStack {
                Circle().fill(grad)
                Image(systemName: "mic.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)
            .shadow(color: .black.opacity(p ? 0.1 : 0.4), radius: p ? 1 : 4, x: 0, y: 3)
        }
    }
}

private struct TactileKey: View {
    let title: String; var small: Bool = false; let action: () -> Void
    init(_ title: String, small: Bool = false, action: @escaping () -> Void) {
        self.title = title; self.small = small; self.action = action
    }
    var body: some View {
        Pressable(action: action) { p in
            Text(title)
                .font(.system(size: small ? 10 : 11, weight: .bold))
                .foregroundColor(.white.opacity(p ? 0.6 : 0.9))
                .frame(maxWidth: .infinity).frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: p ? [Palette.keyLo, Palette.keyLo] : [Palette.keyHi, Palette.keyLo],
                                             startPoint: .top, endPoint: .bottom))
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(p ? 0.02 : 0.12), lineWidth: 1))
                .shadow(color: .black.opacity(p ? 0.1 : 0.4), radius: p ? 1 : 3, x: 0, y: 2)
        }
    }
}

private struct CircleKey: View {
    let glyph: String; var size: CGFloat = 44; let action: () -> Void
    var body: some View {
        Pressable(action: action) { p in
            Image(systemName: glyph)
                .font(.system(size: size * 0.40, weight: .bold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(RaisedCircle(pressed: p))
        }
    }
}

private struct DirKey: View {
    let glyph: String; let action: () -> Void
    var body: some View {
        Pressable(action: action) { p in
            Image(systemName: glyph)
                .font(.system(size: 19, weight: .heavy))
                .foregroundColor(.white.opacity(p ? 0.5 : 0.95))
                .frame(width: 44, height: 44)
        }
    }
}

private struct OKKey: View {
    let action: () -> Void
    var body: some View {
        Pressable(action: action) { p in
            Text("OK")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.white)
                .frame(width: 74, height: 78)
                .background(
                    Circle().fill(LinearGradient(colors: p ? [Palette.keyLo, Palette.ringLo] : [Palette.keyHi, Palette.keyLo],
                                                 startPoint: .top, endPoint: .bottom))
                )
                .overlay(Circle().stroke(Color.white.opacity(p ? 0.04 : 0.18), lineWidth: 1))
                .shadow(color: .black.opacity(p ? 0.1 : 0.5), radius: p ? 1 : 5, x: 0, y: 3)
        }
    }
}

private struct NumberKey: View {
    let n: Int; let action: () -> Void
    var body: some View {
        Pressable(action: action) { p in
            Text("\(n)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(p ? 0.6 : 1.0))
                .frame(width: 44, height: 42)
                .background(RaisedCircle(pressed: p))
        }
    }
}

private struct RockerBtn: View {
    let glyph: String; let action: () -> Void
    init(_ glyph: String, action: @escaping () -> Void) { self.glyph = glyph; self.action = action }
    var body: some View {
        Pressable(action: action) { p in
            Image(systemName: glyph)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(p ? Palette.accent : .white)
                .frame(maxWidth: .infinity).frame(height: 38)
        }
    }
}

private struct AppPill: View {
    let title: String; let colors: [Color]; let action: () -> Void
    var body: some View {
        Pressable(action: action) { p in
            Text(title)
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                )
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
                .shadow(color: colors[0].opacity(p ? 0.1 : 0.4), radius: p ? 1 : 5, x: 0, y: 3)
        }
    }
}

private struct ColorKey: View {
    let colors: [Color]; let action: () -> Void
    var body: some View {
        Pressable(action: action) { p in
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
                .frame(width: 44, height: 24)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
                .shadow(color: colors[0].opacity(p ? 0.1 : 0.4), radius: p ? 1 : 4, x: 0, y: 2)
        }
    }
}

#Preview {
    RemoteView().environmentObject(TVState())
}
