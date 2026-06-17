import Foundation
import Network

@MainActor
class TVRemoteClient: ObservableObject {
    @Published var state: ConnectionState = .disconnected

    private var connection: NWConnection?
    private var receiveBuffer = Data()
    private let host: String
    private let port: UInt16 = 6466

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
        state = .connecting
        let tlsOptions = NWProtocolTLS.Options()

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

        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
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
        connection?.cancel()
        connection = nil
        state = .disconnected
    }

    func sendKey(_ keyCode: Int, direction: KeyDirection = .short) {
        guard state == .connected else { return }
        send(TVMessage.keyInject(keyCode: keyCode, direction: direction))
    }

    private func handleStateChange(_ nwState: NWConnection.State) {
        switch nwState {
        case .ready:
            state = .connected
            send(TVMessage.configureRequest())
            send(TVMessage.setActiveRequest())
            receiveLoop()
        case .failed(let error):
            state = .failed(error.localizedDescription)
        case .cancelled:
            state = .disconnected
        default:
            break
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
                self.receiveLoop()
            }
        }
    }

    private func processBuffer() {
        while receiveBuffer.count >= 2 {
            let length = Int(receiveBuffer[0]) << 8 | Int(receiveBuffer[1])
            guard receiveBuffer.count >= 2 + length else { break }

            let messageData = receiveBuffer.subdata(in: 0..<(2 + length))
            receiveBuffer.removeSubrange(0..<(2 + length))

            if let msg = IncomingMessage.parse(from: messageData), msg.isPingRequest {
                send(TVMessage.pingResponse(val1: msg.pingVal1))
            }
        }
    }
}
