import Foundation
import Combine
import SwiftUI
import UIKit
import os

private let logger = os.Logger(subsystem: "com.local.xiaomiremote", category: "AppState")

@MainActor
public final class AppState: ObservableObject {
    // MARK: - Navigation State
    @Published public var selectedTab: Int = 0

    // MARK: - TV Devices & Connection State
    @Published public var devices: [TVDevice] = []
    @Published public var connectedDevice: TVDevice? = nil
    @Published public var connectionStatus: ConnectionStatus = .disconnected
    @Published public var lastError: String? = nil
    @Published public var lastConnectionDate: Date? = nil
    @Published public var isScanning: Bool = false

    // MARK: - Pairing Sheet State
    @Published public var showPairingSheet: Bool = false
    @Published public var pairingCode: String = ""
    @Published public var pairingClient: PairingClient? = nil

    // MARK: - UI Controls State
    @Published public var showNumericKeypad: Bool = false
    @Published public var manualIPInput: String = ""

    // MARK: - Settings Persistence
    @Published public var hapticFeedbackEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedbackEnabled") }
    }
    @Published public var soundFeedbackEnabled: Bool {
        didSet { UserDefaults.standard.set(soundFeedbackEnabled, forKey: "soundFeedbackEnabled") }
    }
    @Published public var keepScreenAwake: Bool {
        didSet {
            UserDefaults.standard.set(keepScreenAwake, forKey: "keepScreenAwake")
            UIApplication.shared.isIdleTimerDisabled = keepScreenAwake
        }
    }
    @Published public var autoReconnect: Bool {
        didSet { UserDefaults.standard.set(autoReconnect, forKey: "autoReconnect") }
    }
    @Published public var selectedBrand: TVBrand {
        didSet { UserDefaults.standard.set(selectedBrand.rawValue, forKey: "selectedBrand") }
    }

    // MARK: - Services
    public let networkService = NetworkRemoteService()
    public let discovery = DeviceDiscovery()
    private var cancellables = Set<AnyCancellable>()
    private var bgTask: UIBackgroundTaskIdentifier = .invalid

    public init() {
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

    public func connect(to device: TVDevice) {
        saveConnectedDevice(device)
        let pairedKey = "paired_\(device.host)"
        let isAlreadyPaired = UserDefaults.standard.bool(forKey: pairedKey)
        
        if isAlreadyPaired {
            networkService.connect(to: device)
        } else {
            startPairing(device: device)
        }
    }

    public func connectManualIP() {
        let ip = manualIPInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ip.isEmpty else { return }
        let device = TVDevice(id: ip, name: "Smart TV (\(ip))", host: ip, brand: selectedBrand)
        connect(to: device)
    }

    public func disconnect() {
        networkService.disconnect()
    }

    public func forgetDevice(_ device: TVDevice) {
        UserDefaults.standard.set(false, forKey: "paired_\(device.host)")
        if connectedDevice?.id == device.id {
            disconnect()
            connectedDevice = nil
            UserDefaults.standard.removeObject(forKey: "savedConnectedDevice")
        }
    }

    public func sendCommand(_ command: RemoteCommand) {
        if hapticFeedbackEnabled {
            let gen = UIImpactFeedbackGenerator(style: .medium)
            gen.impactOccurred()
        }
        networkService.sendCommand(command)
    }

    // MARK: - Discovery
    public func startScan() {
        discovery.start()
    }

    public func stopScan() {
        discovery.stop()
    }

    // MARK: - Pairing
    public func startPairing(device: TVDevice) {
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

    public func submitPairingCode() {
        pairingClient?.submitCode(pairingCode)
    }

    public func cancelPairing() {
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

    public func reconnectIfNeeded() {
        guard autoReconnect, let device = connectedDevice else { return }
        if connectionStatus == .disconnected || connectionStatus.isConnecting == false {
            networkService.connect(to: device)
        }
    }

    public func beginBackgroundHold() {
        endBackgroundHold()
        bgTask = UIApplication.shared.beginBackgroundTask(withName: "tv-keepalive") { [weak self] in
            self?.endBackgroundHold()
        }
    }

    public func endBackgroundHold() {
        if bgTask != .invalid {
            UIApplication.shared.endBackgroundTask(bgTask)
            bgTask = .invalid
        }
    }
}
