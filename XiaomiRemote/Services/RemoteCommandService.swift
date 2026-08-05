import Foundation
import Combine
import SwiftUI
import os

private let logger = os.Logger(subsystem: "com.local.xiaomiremote", category: "RemoteService")

// MARK: - Remote Command Service Protocol
@MainActor
protocol RemoteCommandService: ObservableObject {
    var connectionStatus: ConnectionStatus { get }
    func connect(to device: TVDevice)
    func disconnect()
    func sendCommand(_ command: RemoteCommand)
}

// MARK: - Network Remote Service (Real Production Implementation)
@MainActor
final class NetworkRemoteService: RemoteCommandService, ObservableObject {
    @Published private(set) var connectionStatus: ConnectionStatus = .disconnected

    private var activeDevice: TVDevice?
    private var remoteClient: TVRemoteClient?
    private var clientCancellable: AnyCancellable?

    init() {}

    func connect(to device: TVDevice) {
        logger.info("Solicitando conexión a \(device.name, privacy: .public) (\(device.host, privacy: .public))")
        activeDevice = device
        disconnectClient()

        connectionStatus = .connecting
        let client = TVRemoteClient(host: device.host)
        
        clientCancellable = client.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .connected:
                    logger.info("Conexión establecida exitosamente con \(device.host, privacy: .public)")
                    self.connectionStatus = .connected
                case .connecting:
                    self.connectionStatus = .connecting
                case .failed(let msg):
                    logger.error("Error de conexión con \(device.host, privacy: .public): \(msg, privacy: .public)")
                    self.connectionStatus = .failed(msg)
                case .disconnected:
                    self.connectionStatus = .disconnected
                }
            }

        self.remoteClient = client
        client.connect()
    }

    func disconnect() {
        logger.info("Desconectando cliente...")
        disconnectClient()
        connectionStatus = .disconnected
    }

    private func disconnectClient() {
        clientCancellable?.cancel()
        clientCancellable = nil
        remoteClient?.disconnect()
        remoteClient = nil
    }

    func sendCommand(_ command: RemoteCommand) {
        guard connectionStatus == .connected, let client = remoteClient else {
            logger.warning("Intento de envío de comando sin conexión activa: \(String(describing: command))")
            return
        }

        if let link = command.appDeepLink {
            logger.info("Lanzando app deep-link: \(link, privacy: .public)")
            client.launchApp(link)
        } else if let code = command.androidKeyCode {
            logger.info("Enviando keycode: \(code)")
            client.sendKey(code, direction: .short)
        }
    }
}

// MARK: - Mock Remote Service (For SwiftUI Previews and Offline Testing)
@MainActor
final class MockRemoteService: RemoteCommandService, ObservableObject {
    @Published private(set) var connectionStatus: ConnectionStatus = .disconnected
    var lastSentCommand: RemoteCommand?

    init(initialStatus: ConnectionStatus = .connected) {
        self.connectionStatus = initialStatus
    }

    func connect(to device: TVDevice) {
        connectionStatus = .connecting
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.connectionStatus = .connected
        }
    }

    func disconnect() {
        connectionStatus = .disconnected
    }

    func sendCommand(_ command: RemoteCommand) {
        lastSentCommand = command
        logger.info("[MOCK] Comando enviado: \(String(describing: command))")
    }
}
