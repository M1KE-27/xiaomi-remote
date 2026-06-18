import Foundation
import Combine

@MainActor
class TVState: ObservableObject {
    static let defaultHost = "192.168.3.17"

    @Published var tvHost: String = UserDefaults.standard.string(forKey: "tvHost") ?? TVState.defaultHost
    @Published var client: TVRemoteClient?

    @Published var pairing: PairingClient?
    @Published var showPairing = false
    @Published var pairingCode = ""

    let discovery = DeviceDiscovery()

    private var cancellables = Set<AnyCancellable>()

    private func pairedKey(_ host: String) -> String { "paired_\(host)" }
    private func isPaired(_ host: String) -> Bool {
        UserDefaults.standard.bool(forKey: pairedKey(host))
    }

    var isConnected: Bool { client?.state == .connected }

    var connectionStateLabel: String {
        switch client?.state {
        case .connected: return "Conectado"
        case .connecting: return "Conectando..."
        case .failed(let msg): return "Error: \(msg)"
        default: return "Desconectado"
        }
    }

    // MARK: - Connect / pair

    /// Entry point from the UI. Pairs first if this TV has never been paired.
    func connect() {
        guard !tvHost.isEmpty else { return }
        if isPaired(tvHost) {
            openRemote()
        } else {
            startPairing()
        }
    }

    /// Used at launch: only reconnects silently if already paired. Never starts
    /// pairing on its own (that must be a deliberate user action). Returns true
    /// if a remote connection was started.
    @discardableResult
    func connectIfPaired() -> Bool {
        guard !tvHost.isEmpty, isPaired(tvHost) else { return false }
        openRemote()
        return true
    }

    func startPairing() {
        guard !tvHost.isEmpty else { return }
        pairingCode = ""
        let pc = PairingClient(host: tvHost)
        pc.onPaired = { [weak self] in
            guard let self else { return }
            UserDefaults.standard.set(true, forKey: self.pairedKey(self.tvHost))
            self.showPairing = false
            self.openRemote()
        }
        // Mirror the pairing client's published changes so SwiftUI updates.
        pc.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        pairing = pc
        showPairing = true
        pc.start()
    }

    func submitPairingCode() {
        pairing?.submitCode(pairingCode)
    }

    func cancelPairing() {
        pairing?.cancel()
        pairing = nil
        showPairing = false
    }

    private var clientCancellable: AnyCancellable?

    private func openRemote() {
        client?.disconnect()                 // cierra cualquier conexión previa
        let c = TVRemoteClient(host: tvHost)
        clientCancellable = c.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
        client = c
        c.connect()
    }

    func disconnect() {
        client?.disconnect()
        client = nil
    }

    /// Forget pairing for the current TV (forces a fresh code next time).
    func forgetPairing() {
        UserDefaults.standard.set(false, forKey: pairedKey(tvHost))
        disconnect()
    }

    // MARK: - Discovery

    func startScan() { discovery.start() }
    func stopScan() { discovery.stop() }

    func select(_ device: DiscoveredDevice) {
        saveHost(device.host)
        discovery.stop()
        connect()
    }

    // MARK: - Input

    func press(_ key: RemoteKey) {
        client?.sendKey(key.rawValue, direction: .short)
    }

    /// Envío directo por keycode Android (para la UI nueva del mando).
    func pressCode(_ code: Int) {
        client?.sendKey(code, direction: .short)
    }

    /// Lanzar una app por deep-link (Netflix, Prime, etc.).
    func launchApp(_ link: String) {
        client?.launchApp(link)
    }

    /// Reconecta al volver del segundo plano si está emparejado y no hay ya una
    /// conexión activa o en curso.
    func reconnectIfNeeded() {
        guard !tvHost.isEmpty, isPaired(tvHost) else { return }
        switch client?.state {
        case .connected, .connecting:
            return                       // ya está (o reintentando solo)
        default:
            openRemote()
        }
    }

    func longPress(_ key: RemoteKey) {
        client?.sendKey(key.rawValue, direction: .startLong)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.client?.sendKey(key.rawValue, direction: .endLong)
        }
    }

    func saveHost(_ host: String) {
        tvHost = host
        UserDefaults.standard.set(host, forKey: "tvHost")
    }
}
