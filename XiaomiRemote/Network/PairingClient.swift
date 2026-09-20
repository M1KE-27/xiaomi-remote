import Foundation
import Network
import Security
import CryptoKit
import Combine
import os

private let logger = os.Logger(subsystem: "com.local.xiaomiremote", category: "PairingClient")

/// Implements the Android TV Remote v2 ("polo") pairing handshake on port 6467.
/// The TV shows a 6-hex-digit code; the user types it and we prove possession of
/// the same client certificate that will later be used on the remote port 6466.
@MainActor
final class PairingClient: ObservableObject {

    enum State: Equatable {
        case idle
        case connecting
        case handshaking
        case awaitingCode        // TV is now showing the code on screen
        case verifying
        case paired
        case failed(String)
    }

    @Published var state: State = .idle

    private var connection: NWConnection?
    private var receiveBuffer = Data()
    private let host: String
    private let port: UInt16 = 6467

    private var clientKey: (modulus: Data, exponent: Data)?
    private var serverKey: (modulus: Data, exponent: Data)?

    /// How many server frames we've consumed during the pre-code handshake.
    private var handshakeStep = 0

    var onPaired: (() -> Void)?

    init(host: String) {
        self.host = host
    }

    // MARK: - Connection

    func start() {
        logger.info("Iniciando emparejamiento con \(self.host):\(self.port)")
        state = .connecting
        handshakeStep = 0
        receiveBuffer.removeAll()

        guard let identity = TVIdentity.load(),
              let cert = TVIdentity.certificate(of: identity),
              let parts = TVIdentity.rsaPublicKeyParts(of: cert) else {
            logger.error("No se pudo cargar el certificado de la app (tv_identity.p12)")
            state = .failed("No se pudo cargar el certificado de la app")
            return
        }
        clientKey = parts

        let tlsOptions = NWProtocolTLS.Options()
        guard let secIdentity = sec_identity_create(identity) else {
            logger.error("Error creando SecIdentity para TLS")
            state = .failed("Identidad TLS inválida")
            return
        }
        sec_protocol_options_set_local_identity(tlsOptions.securityProtocolOptions, secIdentity)
        
        // Android TV Netty server ONLY supports TLS 1.2!
        sec_protocol_options_set_min_tls_protocol_version(tlsOptions.securityProtocolOptions, .TLSv12)
        sec_protocol_options_set_max_tls_protocol_version(tlsOptions.securityProtocolOptions, .TLSv12)

        sec_protocol_options_set_verify_block(
            tlsOptions.securityProtocolOptions,
            { [weak self] _, trust, complete in
                let secTrust = sec_trust_copy_ref(trust).takeRetainedValue()
                _ = SecTrustEvaluateWithError(secTrust, nil)
                if let chain = SecTrustCopyCertificateChain(secTrust) as? [SecCertificate],
                   let leaf = chain.first,
                   let parts = TVIdentity.rsaPublicKeyParts(of: leaf) {
                    Task { @MainActor in self?.serverKey = parts }
                } else if SecTrustGetCertificateCount(secTrust) > 0,
                          let leaf = SecTrustGetCertificateAtIndex(secTrust, 0),
                          let parts = TVIdentity.rsaPublicKeyParts(of: leaf) {
                    Task { @MainActor in self?.serverKey = parts }
                }
                complete(true)  // TV uses a self-signed cert; trust is established via the code
            },
            .global()
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
            Task { @MainActor in self?.handleStateChange(nwState) }
        }
        connection?.start(queue: .global(qos: .userInitiated))
    }

    func cancel() {
        logger.info("Cancelando emparejamiento")
        connection?.cancel()
        connection = nil
        state = .idle
    }

    private func handleStateChange(_ nwState: NWConnection.State) {
        switch nwState {
        case .ready:
            logger.info("Conexión TLS 1.2 lista en puerto 6467. Iniciando handshake...")
            state = .handshaking
            send(PairingMessages.pairingRequest(clientName: "iPhone Remote"))
            receiveLoop()
        case .failed(let error):
            logger.error("Fallo de conexión en emparejamiento: \(error.localizedDescription)")
            state = .failed(error.localizedDescription)
        case .cancelled:
            switch state {
            case .paired, .failed: break
            default: state = .idle
            }
        default:
            break
        }
    }

    // MARK: - Send / receive

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
            handleMessage(payload)
        }
    }

    private func handleMessage(_ payload: Data) {
        // Top-level status field (2). Anything >= 400 is an error from the TV.
        if let status = payload.protobufVarintField(2), status >= 400 {
            logger.error("TV reportó error en pairing: \(status)")
            state = .failed(status == 402 ? "Código incorrecto" : "Error del TV (\(status))")
            connection?.cancel()
            return
        }

        switch state {
        case .handshaking:
            handshakeStep += 1
            logger.info("Handshake step recibido: \(self.handshakeStep)")
            switch handshakeStep {
            case 1:  // got pairing_request_ack -> send options
                logger.info("Enviando opciones de emparejamiento (hex, 6 dígitos)...")
                send(PairingMessages.options())
            case 2:  // got options ack -> send configuration
                logger.info("Enviando configuración de emparejamiento...")
                send(PairingMessages.configuration())
            default: // got configuration_ack -> TV now shows the code
                logger.info("¡Configuración aceptada por el TV! Esperando que el usuario introduzca el código mostrado en pantalla.")
                state = .awaitingCode
            }
        case .verifying:
            // secret_ack received
            logger.info("¡Código aceptado por el TV! Emparejamiento completado con éxito.")
            state = .paired
            connection?.cancel()
            onPaired?()
        default:
            break
        }
    }

    // MARK: - Code entry

    /// Called from the UI with the code the TV shows. Computes and sends the secret.
    func submitCode(_ rawCode: String) {
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        logger.info("Procesando código de vinculación introducido por el usuario: \(code)")
        guard state == .awaitingCode else {
            logger.warning("submitCode llamado fuera del estado awaitingCode (estado actual: \(String(describing: self.state)))")
            return
        }
        guard let clientKey, let serverKey else {
            logger.error("Faltan claves clientKey o serverKey para calcular el secreto")
            state = .failed("No se obtuvieron las claves del handshake")
            return
        }
        guard let codeBytes = Self.hexToBytes(code), codeBytes.count >= 2 else {
            logger.error("Formato de código inválido (debe tener al menos 4 caracteres hexadecimales)")
            state = .failed("El código debe ser hexadecimal (ej: A1B2C3)")
            return
        }

        var hasher = SHA256()
        hasher.update(data: clientKey.modulus)
        hasher.update(data: clientKey.exponent)
        hasher.update(data: serverKey.modulus)
        hasher.update(data: serverKey.exponent)
        hasher.update(data: Data(codeBytes[1...]))      // nonce = code without the check byte
        let digest = Data(hasher.finalize())

        guard digest.first == codeBytes.first else {
            logger.error("Check byte del código no coincide con SHA256 calculado")
            state = .failed("Código incorrecto, vuelve a intentarlo")
            return
        }

        logger.info("Check byte válido. Enviando secreto al TV...")
        state = .verifying
        send(PairingMessages.secret(digest))
    }

    private static func hexToBytes(_ hex: String) -> [UInt8]? {
        let clean = hex.filter { $0.isHexDigit }
        guard clean.count % 2 == 0 else { return nil }
        var bytes = [UInt8]()
        var i = clean.startIndex
        while i < clean.endIndex {
            let j = clean.index(i, offsetBy: 2)
            guard let b = UInt8(clean[i..<j], radix: 16) else { return nil }
            bytes.append(b)
            i = j
        }
        return bytes
    }
}

// MARK: - Pairing message builders

enum PairingMessages {
    private static let STATUS_OK: UInt64 = 200
    private static let ENCODING_HEX: UInt64 = 3
    private static let ROLE_INPUT: UInt64 = 1
    private static let SYMBOL_LENGTH: UInt64 = 6

    static func pairingRequest(clientName: String) -> Data {
        build {
            $0.putVarint(1, value: 2)                    // protocol_version
            $0.putVarint(2, value: STATUS_OK)            // status
            $0.putMessage(10) { req in                   // pairing_request
                req.putString(1, value: "androidtvremote")  // service_name
                req.putString(2, value: clientName)          // client_name
            }
        }
    }

    static func options() -> Data {
        build {
            $0.putVarint(1, value: 2)
            $0.putVarint(2, value: STATUS_OK)
            $0.putMessage(20) { opt in                   // pairing_option
                opt.putMessage(1) { enc in               // input_encodings
                    enc.putVarint(1, value: ENCODING_HEX)
                    enc.putVarint(2, value: SYMBOL_LENGTH)
                }
                opt.putVarint(3, value: ROLE_INPUT)      // preferred_role
            }
        }
    }

    static func configuration() -> Data {
        build {
            $0.putVarint(1, value: 2)
            $0.putVarint(2, value: STATUS_OK)
            $0.putMessage(30) { cfg in                   // pairing_configuration
                cfg.putMessage(1) { enc in               // encoding
                    enc.putVarint(1, value: ENCODING_HEX)
                    enc.putVarint(2, value: SYMBOL_LENGTH)
                }
                cfg.putVarint(2, value: ROLE_INPUT)      // client_role
            }
        }
    }

    static func secret(_ digest: Data) -> Data {
        build {
            $0.putVarint(1, value: 2)
            $0.putVarint(2, value: STATUS_OK)
            $0.putMessage(40) { sec in                   // pairing_secret
                sec.putLengthDelimited(1, bytes: digest) // secret
            }
        }
    }

    private static func build(_ body: (inout ProtobufEncoder) -> Void) -> Data {
        var msg = ProtobufEncoder()
        body(&msg)
        return msg.build().withLengthPrefix()
    }
}
