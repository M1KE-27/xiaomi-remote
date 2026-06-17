import Foundation
import Combine

@MainActor
class TVState: ObservableObject {
    @Published var tvHost: String = UserDefaults.standard.string(forKey: "tvHost") ?? ""
    @Published var client: TVRemoteClient?
    @Published var showPairing = false

    var isConnected: Bool {
        client?.state == .connected
    }

    var connectionStateLabel: String {
        switch client?.state {
        case .connected: return "Conectado"
        case .connecting: return "Conectando..."
        case .failed(let msg): return "Error: \(msg)"
        default: return "Desconectado"
        }
    }

    func connect() {
        guard !tvHost.isEmpty else { return }
        client = TVRemoteClient(host: tvHost)
        client?.connect()
    }

    func disconnect() {
        client?.disconnect()
        client = nil
    }

    func press(_ key: RemoteKey) {
        client?.sendKey(key.rawValue, direction: .short)
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
