import Foundation
import Network
import Combine
import os

private let logger = os.Logger(subsystem: "com.local.xiaomiremote", category: "DeviceDiscovery")

struct DiscoveredDevice: Identifiable, Equatable {
    let id: String      // service name or unique host
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
    private var netResolvers: [BonjourResolver] = []

    init() {
        // Pre-poblar dispositivos conocidos de la red local
        devices = [
            DiscoveredDevice(id: "MiTV-MSSP2", name: "Xiaomi Mi TV (Salón)", host: "192.168.3.17"),
            DiscoveredDevice(id: "MiTV-MSSP3", name: "Xiaomi TV (Dormitorio)", host: "192.168.3.15")
        ]
    }

    func start() {
        stop()
        isScanning = true
        logger.info("Iniciando escaneo de red local...")

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

        // Probar también IPs conocidas directamente en segundo plano
        probeKnownHost("192.168.3.17", defaultName: "Xiaomi Mi TV (192.168.3.17)")
        probeKnownHost("192.168.3.15", defaultName: "Xiaomi TV (192.168.3.15)")

        // Stop scanning after a reasonable window.
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
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
        netResolvers.removeAll()
        isScanning = false
    }

    private func handle(_ results: Set<NWBrowser.Result>) {
        for result in results {
            if case let .service(name, type, domain, _) = result.endpoint {
                logger.info("Dispositivo Bonjour detectado: \(name) (\(type))")
                resolveWithNetService(name: name, type: type, domain: domain)
                resolve(endpoint: result.endpoint, name: name)
            }
        }
    }

    private func resolveWithNetService(name: String, type: String, domain: String) {
        let resolver = BonjourResolver(name: name, domain: domain, type: type)
        netResolvers.append(resolver)
        resolver.resolve(timeout: 5.0) { [weak self, weak resolver] ip in
            Task { @MainActor in
                if let ip = ip, !ip.isEmpty {
                    logger.info("Bonjour resuelto via NetService: \(name) -> \(ip)")
                    self?.add(name: name, host: ip)
                }
                if let r = resolver {
                    self?.netResolvers.removeAll { $0 === r }
                }
            }
        }
    }

    private func resolve(endpoint: NWEndpoint, name: String) {
        let tlsOptions = NWProtocolTLS.Options()
        sec_protocol_options_set_min_tls_protocol_version(tlsOptions.securityProtocolOptions, .TLSv12)
        sec_protocol_options_set_max_tls_protocol_version(tlsOptions.securityProtocolOptions, .TLSv12)
        sec_protocol_options_set_verify_block(tlsOptions.securityProtocolOptions, { _, _, complete in complete(true) }, .global())
        let params = NWParameters(tls: tlsOptions)

        let conn = NWConnection(to: endpoint, using: params)
        conn.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                if let remote = conn.currentPath?.remoteEndpoint,
                   case let .hostPort(host, _) = remote {
                    let ip = String(describing: host).components(separatedBy: "%").first ?? ""
                    if !ip.isEmpty {
                        Task { @MainActor in self?.add(name: name, host: ip) }
                    }
                }
                conn.cancel()
            case .failed, .cancelled:
                Task { @MainActor in self?.resolvers.removeAll { $0 === conn } }
            default:
                break
            }
        }
        resolvers.append(conn)
        conn.start(queue: .global(qos: .userInitiated))
    }

    private func probeKnownHost(_ host: String, defaultName: String) {
        guard let port = NWEndpoint.Port(rawValue: 6466) else { return }
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: port)
        let conn = NWConnection(to: endpoint, using: .tcp)
        conn.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                Task { @MainActor in
                    self?.add(name: defaultName, host: host)
                }
                conn.cancel()
            default:
                break
            }
        }
        resolvers.append(conn)
        conn.start(queue: .global(qos: .utility))
    }

    private func add(name: String, host: String) {
        guard !devices.contains(where: { $0.host == host }) else { return }
        devices.append(DiscoveredDevice(id: host, name: friendlyName(name), host: host))
    }

    private func friendlyName(_ raw: String) -> String {
        raw.replacingOccurrences(of: "\\032", with: " ")
           .replacingOccurrences(of: "-", with: " ")
    }
}

// MARK: - Bonjour NetService Resolver
final class BonjourResolver: NSObject, NetServiceDelegate {
    private let service: NetService
    private var completion: ((String?) -> Void)?

    init(name: String, domain: String, type: String) {
        let cleanType = type.hasSuffix(".") ? type : "\(type)."
        let cleanDomain = domain.hasSuffix(".") ? domain : "\(domain)."
        self.service = NetService(domain: cleanDomain, type: cleanType, name: name)
        super.init()
        self.service.delegate = self
    }

    func resolve(timeout: TimeInterval, completion: @escaping (String?) -> Void) {
        self.completion = completion
        self.service.resolve(withTimeout: timeout)
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let addresses = sender.addresses else {
            completion?(nil)
            return
        }
        for data in addresses {
            var storage = sockaddr_storage()
            data.copyBytes(to: UnsafeMutableBufferPointer(start: &storage, count: 1))
            if storage.ss_family == UInt8(AF_INET) {
                var addr = withUnsafePointer(to: &storage) {
                    $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                }
                var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                if let cStr = inet_ntop(AF_INET, &addr.sin_addr, &buffer, socklen_t(INET_ADDRSTRLEN)) {
                    let ip = String(cString: cStr)
                    completion?(ip)
                    completion = nil
                    return
                }
            }
        }
        completion?(nil)
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        completion?(nil)
        completion = nil
    }
}
