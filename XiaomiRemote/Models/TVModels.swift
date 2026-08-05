import Foundation
import SwiftUI

// MARK: - TV Brand
public enum TVBrand: String, CaseIterable, Codable, Identifiable {
    case samsung = "Samsung"
    case lg = "LG WebOS"
    case sony = "Sony Bravia"
    case androidTV = "Android TV"
    case xiaomi = "Xiaomi TV"
    case tcl = "TCL"
    case hisense = "Hisense"
    case philips = "Philips"
    case appleTV = "Apple TV"
    case universal = "Universal"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .samsung, .lg, .sony, .xiaomi, .tcl, .hisense, .philips, .androidTV, .universal:
            return "tv"
        case .appleTV:
            return "appletv"
        }
    }
}

// MARK: - TV Device
public struct TVDevice: Identifiable, Equatable, Codable {
    public let id: String
    public var name: String
    public var host: String
    public var brand: TVBrand
    public var lastConnectedDate: Date?

    public init(id: String, name: String, host: String, brand: TVBrand = .androidTV, lastConnectedDate: Date? = nil) {
        self.id = id
        self.name = name
        self.host = host
        self.brand = brand
        self.lastConnectedDate = lastConnectedDate
    }
}

// MARK: - Connection Status
public enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String)

    public var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    public var isConnecting: Bool {
        if case .connecting = self { return true }
        return false
    }

    public var statusText: String {
        switch self {
        case .disconnected: return "Desconectado"
        case .connecting: return "Conectando…"
        case .connected: return "Conectado"
        case .failed(let err): return "Error: \(err)"
        }
    }

    public var statusColor: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .connected: return Color(red: 0.20, green: 0.78, blue: 0.35) // Green
        case .failed: return .red
        }
    }
}

// MARK: - Remote Command
public enum RemoteCommand: Equatable {
    case power
    case input
    case settings
    case voiceAssistant
    case up
    case down
    case left
    case right
    case ok
    case back
    case home
    case menu
    case volUp
    case volDown
    case mute
    case chUp
    case chDown
    case digit(Int)
    case red
    case green
    case yellow
    case blue
    case info
    case guide
    case netflix
    case prime
    case disney
    case youtube
    case customLink(String)

    public var androidKeyCode: Int? {
        switch self {
        case .power: return 26
        case .back: return 4
        case .home: return 3
        case .menu: return 82
        case .up: return 19
        case .down: return 20
        case .left: return 21
        case .right: return 22
        case .ok: return 23
        case .volUp: return 24
        case .volDown: return 25
        case .mute: return 164
        case .chUp: return 166
        case .chDown: return 167
        case .voiceAssistant: return 219
        case .input: return 178
        case .settings: return 176
        case .info: return 233
        case .guide: return 172
        case .red: return 183
        case .green: return 184
        case .yellow: return 185
        case .blue: return 186
        case .digit(let d): return 7 + max(0, min(9, d))
        default: return nil
        }
    }

    public var appDeepLink: String? {
        switch self {
        case .netflix: return "https://www.netflix.com/title"
        case .prime: return "https://app.primevideo.com"
        case .disney: return "https://www.disneyplus.com"
        case .youtube: return "https://www.youtube.com"
        case .customLink(let url): return url
        default: return nil
        }
    }
}
