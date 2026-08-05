import Foundation
import Network
import Security

@MainActor
class TVRemoteClient: ObservableObject {
    @Published var state: ConnectionState = .disconnected

    private var connection: NWConnection?
    private var receiveBuffer = Data()
    private let host: String
    private let port: UInt16 = 6466

    private var manualDisconnect = false
    private var reconnectAttempts = 0
    private let maxReconnects = 6

    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case failed(String)
    }

    init(host: String) {
        self.host = host
    }

    func connect() {
        manualDisconnect = false
        connection?.cancel()        // nunca dejamos dos conexiones vivas
        receiveBuffer.removeAll()
        state = .connecting
        let tlsOptions = NWProtocolTLS.Options()

        if let identity = TVIdentity.load(), let secIdentity = sec_identity_create(identity) {
            sec_protocol_options_set_local_identity(tlsOptions.securityProtocolOptions, secIdentity)
        }

        sec_protocol_options_set_verify_block(
            tlsOptions.securityProtocolOptions,
            { _, _, complete in complete(true) },
            .global()
        )

        sec_protocol_options_set_min_tls_protocol_version(
            tlsOptions.securityProtocolOptions,
            .TLSv12
        )

        let params = NWParameters(tls: tlsOptions)
        params.allowLocalEndpointReuse = true

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            state = .failed("Puerto inválido: \(port)")
            return
        }

        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: nwPort
        )

        connection = NWConnection(to: endpoint, using: params)
        connection?.stateUpdateHandler = { [weak self] nwState in
            Task { @MainActor in
                self?.handleStateChange(nwState)
            }
        }
        connection?.start(queue: .global(qos: .userInitiated))
    }

    func disconnect() {
        manualDisconnect = true
        connection?.cancel()
        connection = nil
        state = .disconnected
    }

    func sendKey(_ keyCode: Int, direction: KeyDirection = .short) {
        guard state == .connected else { return }
        send(TVMessage.keyInject(keyCode: keyCode, direction: direction))
    }

    func launchApp(_ link: String) {
        guard state == .connected else { return }
        send(TVMessage.appLink(link))
    }

    private func handleStateChange(_ nwState: NWConnection.State) {
        switch nwState {
        case .ready:
            state = .connected
            reconnectAttempts = 0
            // El handshake lo inicia el TV: nos manda remote_configure y
            // respondemos en processBuffer(). No enviamos nada proactivamente.
            receiveLoop()
        case .failed:
            scheduleReconnect()
        case .cancelled:
            if manualDisconnect { state = .disconnected }
            else { scheduleReconnect() }
        default:
            break
        }
    }

    /// Reintenta la conexión con pequeño retardo cuando se cae sin querer.
    private func scheduleReconnect() {
        guard !manualDisconnect, reconnectAttempts < maxReconnects else {
            state = .failed("Sin conexión con el TV")
            return
        }
        reconnectAttempts += 1
        state = .connecting
        let delay = Double(min(reconnectAttempts, 3))   // 1s, 2s, 3s...
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, !self.manualDisconnect else { return }
            self.connect()
        }
    }

    private func send(_ data: Data) {
        connection?.send(content: data, completion: .idempotent)
    }

    private func receiveLoop() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let data {
                Task { @MainActor in
                    self.receiveBuffer.append(data)
                    self.processBuffer()
                }
            }
            if !isComplete && error == nil {
                Task { @MainActor in self.receiveLoop() }
            }
        }
    }

    private func processBuffer() {
        while let payload = Data.nextFrame(from: &receiveBuffer) {
            let msg = IncomingMessage(payload: payload)
            if msg.isConfigureRequest {
                // El TV pide configuración -> respondemos y activamos la sesión.
                send(TVMessage.configureResponse())
                send(TVMessage.setActive())
            } else if msg.isPingRequest {
                send(TVMessage.pingResponse(val1: msg.pingVal1))
            }
        }
    }
}
