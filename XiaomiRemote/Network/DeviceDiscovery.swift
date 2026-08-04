import Foundation
import Network
import Combine

struct DiscoveredDevice: Identifiable, Equatable {
    let id: String      // service name
    let name: String
    let host: String    // resolved IP
}

/// Discovers Android TV / Google TV devices on the local network via Bonjour
/// (`_androidtvremote2._tcp`) and resolves each to an IP address.
@MainActor
final class DeviceDiscovery: ObservableObject {
    @Published var devices: [DiscoveredDevice] = []
    @Published var isScanning = false

    private var browser: NWBrowser?
    private var resolvers: [NWConnection] = []

    func start() {
        stop()
        devices = []
        isScanning = true

        let params = NWParameters()
        params.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: "_androidtvremote2._tcp", domain: nil), using: params)

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in self?.handle(results) }
        }
        browser.stateUpdateHandler = { [weak self] state in
            if case .failed = state {
                Task { @MainActor in self?.isScanning = false }
            }
        }
        browser.start(queue: .main)
        self.browser = browser

        // Stop scanning after a reasonable window.
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            self?.isScanning = false
            self?.browser?.cancel()
            self?.browser = nil
        }
    }

    func stop() {
        browser?.cancel()
        browser = nil
        resolvers.forEach { $0.cancel() }
        resolvers = []
        isScanning = false
    }

    private func handle(_ results: Set<NWBrowser.Result>) {
        for result in results {
            if case let .service(name, _, _, _) = result.endpoint {
                guard !devices.contains(where: { $0.id == name }) else { continue }
                resolve(endpoint: result.endpoint, name: name)
            }
        }
    }

    private func resolve(endpoint: NWEndpoint, name: String) {
        let conn = NWConnection(to: endpoint, using: .tcp)
        conn.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready, .preparing:
                if let remote = conn.currentPath?.remoteEndpoint,
                   case let .hostPort(host, _) = remote {
                    let ip = String(describing: host).components(separatedBy: "%").first ?? ""
                    if !ip.isEmpty {
                        Task { @MainActor in self?.add(name: name, host: ip) }
                    }
                    conn.cancel()
                }
            case .failed, .cancelled:
                Task { @MainActor in self?.resolvers.removeAll { $0 === conn } }
            default:
                break
            }
        }
        resolvers.append(conn)
        conn.start(queue: .global(qos: .userInitiated))
    }

    private func add(name: String, host: String) {
        guard !devices.contains(where: { $0.id == name }) else { return }
        devices.append(DiscoveredDevice(id: name, name: friendlyName(name), host: host))
    }

    private func friendlyName(_ raw: String) -> String {
        raw.replacingOccurrences(of: "\\032", with: " ")
           .replacingOccurrences(of: "-", with: " ")
    }
}
