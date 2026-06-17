import SwiftUI

struct RemoteView: View {
    @EnvironmentObject var tv: TVState

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 8)
                navigationPad
                Spacer(minLength: 8)
                mediaControls
                Spacer(minLength: 8)
                volumeRow
                Spacer(minLength: 16)
            }
            .padding(.horizontal, 24)
        }
    }

    private var topBar: some View {
        HStack {
            RemoteButton(key: .power, size: 44)
            Spacer()
            RemoteButton(key: .home, size: 44)
            RemoteButton(key: .back, size: 44)
            RemoteButton(key: .menu, size: 44)
        }
        .padding(.top, 12)
    }

    private var navigationPad: some View {
        VStack(spacing: 0) {
            RemoteButton(key: .dpadUp, size: 52)
            HStack(spacing: 0) {
                RemoteButton(key: .dpadLeft, size: 52)
                RemoteButton(key: .dpadCenter, size: 64)
                    .padding(.horizontal, 4)
                RemoteButton(key: .dpadRight, size: 52)
            }
            RemoteButton(key: .dpadDown, size: 52)
        }
        .padding(16)
        .background(
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 220, height: 220)
        )
    }

    private var mediaControls: some View {
        HStack(spacing: 20) {
            RemoteButton(key: .mediaPrev, size: 40)
            RemoteButton(key: .rewind, size: 40)
            RemoteButton(key: .playPause, size: 52)
            RemoteButton(key: .fastForward, size: 40)
            RemoteButton(key: .mediaNext, size: 40)
        }
    }

    private var volumeRow: some View {
        HStack(spacing: 24) {
            RemoteButton(key: .volumeDown, size: 44)
            RemoteButton(key: .volumeMute, size: 40)
            RemoteButton(key: .volumeUp, size: 44)
        }
        .padding(.horizontal, 32)
    }
}

struct RemoteButton: View {
    let key: RemoteKey
    let size: CGFloat
    @EnvironmentObject var tv: TVState
    @GestureState private var pressing = false

    var body: some View {
        Image(systemName: key.systemImage)
            .font(.system(size: size * 0.4, weight: .medium))
            .frame(width: size, height: size)
            .foregroundColor(pressing ? .black : .white)
            .background(
                Circle()
                    .fill(pressing ? Color.white : Color.white.opacity(0.1))
            )
            .scaleEffect(pressing ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: pressing)
            .gesture(
                LongPressGesture(minimumDuration: 0.4)
                    .updating($pressing) { current, state, _ in state = current }
                    .onEnded { _ in tv.longPress(key) }
                    .simultaneously(
                        with: TapGesture().onEnded { tv.press(key) }
                    )
            )
    }
}

#Preview {
    RemoteView()
        .environmentObject(TVState())
}
