import Foundation
import Combine
import SwiftUI
import UIKit
import os

private let logger = os.Logger(subsystem: "com.local.xiaomiremote", category: "AppState")

@MainActor
final class AppState: ObservableObject {
    // MARK: - Navigation State
    @Published var selectedTab: Int = 0

    // MARK: - TV Devices & Connection State
    @Published var devices: [TVDevice] = []
    @Published var connectedDevice: TVDevice? = nil
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastError: String? = nil
    @Published var lastConnectionDate: Date? = nil
    @Published var isScanning: Bool = false

    // MARK: - Pairing Sheet State
    @Published var showPairingSheet: Bool = false
    @Published var pairingCode: String = ""
    @Published var pairingClient: PairingClient? = nil

    // MARK: - UI Controls State
    @Published var showNumericKeypad: Bool = false
    @Published var manualIPInput: String = ""

    // MARK: - Settings Persistence
    @Published var hapticFeedbackEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled") }
    }
    @Published var soundFeedbackEnabled: Bool {
        didSet { UserDefaults.standard.set(soundFeedbackEnabled, forKey: "soundFeedbackEnabled") }
    }
    @Published var keepScreenAwake: Bool {
        didSet {
            UserDefaults.standard.set(keepScreenAwake, forKey: "keepScreenAwake")
            UIApplication.shared.isIdleTimerDisabled = keepScreenAwake
        }
    }
    @Published var autoReconnect: Bool {
        didSet { UserDefaults.standard.set(autoReconnect, forKey: "autoReconnect") }
    }
    @Published var selectedBrand: TVBrand {
        didSet { UserDefaults.standard.set(selectedBrand.rawValue, forKey: "selectedBrand") }
    }

    // MARK: - Services
    let networkService = NetworkRemoteService()
    let discovery = DeviceDiscovery()
    private var cancellables = Set<AnyCancellable>()
    private var bgTask: UIBackgroundTaskIdentifier = .invalid

    init() {
        self.hapticFeedbackEnabled = UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true
        self.soundFeedbackEnabled = UserDefaults.standard.object(forKey: "soundFeedbackEnabled") as? Bool ?? false
        self.keepScreenAwake = UserDefaults.standard.object(forKey: "keepScreenAwake") as? Bool ?? false
        self.autoReconnect = UserDefaults.standard.object(forKey: "autoReconnect") as? Bool ?? true
        
        let savedBrandRaw = UserDefaults.standard.string(forKey: "selectedBrand") ?? TVBrand.samsung.rawValue
        self.selectedBrand = TVBrand(rawValue: savedBrandRaw) ?? .samsung
        
        let savedIP = UserDefaults.standard.string(forKey: "tvHost") ?? "192.168.1.42"
        self.manualIPInput = savedIP

        setupServiceBinding()
        setupDiscoveryBinding()
        
        // Restore last connected device if saved
        if let savedDeviceData = UserDefaults.standard.data(forKey: "savedConnectedDevice"),
           let device = try? JSONDecoder().decode(TVDevice.self, from: savedDeviceData) {
            self.connectedDevice = device
            self.manualIPInput = device.host
        }
    }

    private func setupServiceBinding() {
        networkService.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                self.connectionStatus = status
                if status == .connected {
                    self.lastConnectionDate = Date()
                    self.lastError = nil
                    if var current = self.connectedDevice {
                        current.lastConnectedDate = Date()
                        self.saveConnectedDevice(current)
                    }
                } else if case .failed(let err) = status {
                    self.lastError = err
                }
            }
            .store(in: &cancellables)
    }

    private func setupDiscoveryBinding() {
        discovery.$devices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] discoveredList in
                guard let self = self else { return }
                self.devices = discoveredList.map {
                    TVDevice(id: $0.id, name: $0.name, host: $0.host, brand: self.selectedBrand)
                }
            }
            .store(in: &cancellables)

        discovery.$isScanning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] scanning in
                self?.isScanning = scanning
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func connect(to device: TVDevice) {
        saveConnectedDevice(device)
        let pairedKey = "paired_\(device.host)"
        let isAlreadyPaired = UserDefaults.standard.bool(forKey: pairedKey)
        
        if isAlreadyPaired {
            networkService.connect(to: device)
        } else {
            startPairing(device: device)
        }
    }

    func connectManualIP() {
        let ip = manualIPInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ip.isEmpty else { return }
        let device = TVDevice(id: ip, name: "Smart TV (\(ip))", host: ip, brand: selectedBrand)
        connect(to: device)
    }

    func disconnect() {
        networkService.disconnect()
    }

    func forgetDevice(_ device: TVDevice) {
        UserDefaults.standard.set(false, forKey: "paired_\(device.host)")
        if connectedDevice?.id == device.id {
            disconnect()
            connectedDevice = nil
            UserDefaults.standard.removeObject(forKey: "savedConnectedDevice")
        }
    }

    func sendCommand(_ command: RemoteCommand) {
        if hapticFeedbackEnabled {
            let gen = UIImpactFeedbackGenerator(style: .medium)
            gen.impactOccurred()
        }
        networkService.sendCommand(command)
    }

    // MARK: - Discovery
    func startScan() {
        discovery.start()
    }

    func stopScan() {
        discovery.stop()
    }

    // MARK: - Pairing
    func startPairing(device: TVDevice) {
        pairingCode = ""
        let pc = PairingClient(host: device.host)
        pc.onPaired = { [weak self] in
            guard let self = self else { return }
            UserDefaults.standard.set(true, forKey: "paired_\(device.host)")
            self.showPairingSheet = false
            self.networkService.connect(to: device)
        }
        
        pc.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)

        self.pairingClient = pc
        self.showPairingSheet = true
        pc.start()
    }

    func submitPairingCode() {
        pairingClient?.submitCode(pairingCode)
    }

    func cancelPairing() {
        pairingClient?.cancel()
        pairingClient = nil
        showPairingSheet = false
    }

    // MARK: - Helpers
    private func saveConnectedDevice(_ device: TVDevice) {
        self.connectedDevice = device
        self.manualIPInput = device.host
        UserDefaults.standard.set(device.host, forKey: "tvHost")
        if let encoded = try? JSONEncoder().encode(device) {
            UserDefaults.standard.set(encoded, forKey: "savedConnectedDevice")
        }
    }

    func reconnectIfNeeded() {
        guard autoReconnect, let device = connectedDevice else { return }

        switch connectionStatus {
        case .disconnected, .failed:
            networkService.connect(to: device)

        case .connecting, .connected:
            return
        }
    }

    func beginBackgroundHold() {
        endBackgroundHold()
        bgTask = UIApplication.shared.beginBackgroundTask(withName: "tv-keepalive") { [weak self] in
            self?.endBackgroundHold()
        }
    }

    func endBackgroundHold() {
        if bgTask != .invalid {
            UIApplication.shared.endBackgroundTask(bgTask)
            bgTask = .invalid
        }
    }
}
