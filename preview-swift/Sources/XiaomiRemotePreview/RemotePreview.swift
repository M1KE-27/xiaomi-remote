import TokamakShim

/// Versión Tokamak (navegador) del mando. Misma disposición que RemoteView.swift
/// del app real; los SF Symbols se sustituyen por glifos unicode/emoji.
struct RemotePreview: View {
    @EnvironmentObject var tv: MockTV

    private let body0 = Color(red: 0.16, green: 0.16, blue: 0.18)
    private let body1 = Color(red: 0.09, green: 0.09, blue: 0.10)

    var body: some View {
        ZStack {
            Color.black
            ScrollView {
                VStack(spacing: 10) {
                    topRow
                    numberPad
                    labelRow
                    appRow
                    dpad
                    controlRow
                    colorRow
                    volumeRow
                    Text("Última tecla: \(tv.lastAction)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.top, 6)
                }
                .padding(16)
                .frame(maxWidth: 330)
                .background(RoundedRectangle(cornerRadius: 36).fill(body1))
                .padding(14)
            }
        }
    }

    private var topRow: some View {
        HStack {
            CircleKey("⏻", fg: .red) { tv.press("Power") }
            Spacer()
            GoogleKey { tv.press("Asistente") }
        }
    }

    private var numberPad: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(1...3, id: \.self) { col in
                        let n = row * 3 + col
                        NumKey(n) { tv.press("\(n)") }
                    }
                }
            }
            HStack(spacing: 12) {
                TxtKey("INPUT") { tv.press("INPUT") }
                NumKey(0) { tv.press("0") }
                TxtKey("CH LIST") { tv.press("CH LIST") }
            }
        }
    }

    private var labelRow: some View {
        HStack(spacing: 12) {
            TxtKey("SETTINGS") { tv.press("SETTINGS") }
            TxtKey("TTX") { tv.press("TTX") }
        }
    }

    private var appRow: some View {
        HStack(spacing: 12) {
            PillKey("NETFLIX", bg: Color(red: 0.9, green: 0.04, blue: 0.08)) { tv.launch("Netflix") }
            PillKey("prime video", bg: Color(red: 0.0, green: 0.66, blue: 0.88)) { tv.launch("Prime") }
        }
    }

    private var dpad: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.06)).frame(width: 200, height: 200)
            VStack {
                DirKey("▲") { tv.press("Up") }
                Spacer()
                HStack {
                    DirKey("◀") { tv.press("Left") }
                    Spacer()
                    DirKey("▶") { tv.press("Right") }
                }
                Spacer()
                DirKey("▼") { tv.press("Down") }
            }
            .frame(width: 160, height: 160)
            OKKey { tv.press("OK") }
        }
        .frame(width: 200, height: 200)
    }

    private var controlRow: some View {
        HStack(spacing: 26) {
            CircleKey("Ⓜ") { tv.press("Mi") }
            CircleKey("←") { tv.press("Back") }
            CircleKey("◯") { tv.press("Home") }
        }
    }

    private var colorRow: some View {
        HStack(spacing: 20) {
            ColorKey(.red) { tv.press("Rojo") }
            ColorKey(.green) { tv.press("Verde") }
            ColorKey(.yellow) { tv.press("Amarillo") }
            ColorKey(.blue) { tv.press("Azul") }
        }
    }

    private var volumeRow: some View {
        HStack(spacing: 26) {
            CircleKey("−") { tv.press("Vol -") }
            CircleKey("🔇", size: 40) { tv.press("Mute") }
            CircleKey("＋") { tv.press("Vol +") }
        }
    }
}

// MARK: - Botones (Tokamak)

private struct CircleKey: View {
    let glyph: String; var fg: Color = .white; var size: CGFloat = 44; let action: () -> Void
    init(_ glyph: String, fg: Color = .white, size: CGFloat = 44, action: @escaping () -> Void) {
        self.glyph = glyph; self.fg = fg; self.size = size; self.action = action
    }
    var body: some View {
        Button(action: action) {
            Text(glyph)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(fg)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.white.opacity(0.12)))
        }
    }
}

private struct DirKey: View {
    let glyph: String; let action: () -> Void
    init(_ glyph: String, action: @escaping () -> Void) { self.glyph = glyph; self.action = action }
    var body: some View {
        Button(action: action) {
            Text(glyph).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                .frame(width: 40, height: 40)
        }
    }
}

private struct OKKey: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("OK").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Circle().fill(Color.white.opacity(0.18)))
        }
    }
}

private struct NumKey: View {
    let n: Int; let action: () -> Void
    init(_ n: Int, action: @escaping () -> Void) { self.n = n; self.action = action }
    var body: some View {
        Button(action: action) {
            Text("\(n)").font(.system(size: 19, weight: .semibold)).foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.10)))
        }
    }
}

private struct TxtKey: View {
    let title: String; let action: () -> Void
    init(_ title: String, action: @escaping () -> Void) { self.title = title; self.action = action }
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 36)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.10)))
        }
    }
}

private struct PillKey: View {
    let title: String; let bg: Color; let action: () -> Void
    init(_ title: String, bg: Color, action: @escaping () -> Void) { self.title = title; self.bg = bg; self.action = action }
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 38)
                .background(RoundedRectangle(cornerRadius: 19).fill(bg))
        }
    }
}

private struct ColorKey: View {
    let color: Color; let action: () -> Void
    init(_ color: Color, action: @escaping () -> Void) { self.color = color; self.action = action }
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 7).fill(color).frame(width: 42, height: 26)
        }
    }
}

private struct GoogleKey: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text("🎙")
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.12)))
        }
    }
}
