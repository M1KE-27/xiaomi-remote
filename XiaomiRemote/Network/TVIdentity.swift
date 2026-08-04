import Foundation
import Security

/// Shared access to the bundled TLS client identity (tv_identity.p12) and helpers
/// to extract RSA public-key parts needed by the Android TV pairing handshake.
enum TVIdentity {
    static let passphrase = "xiaomiremote"

    static func load() -> SecIdentity? {
        guard let url = Bundle.main.url(forResource: "tv_identity", withExtension: "p12"),
              let data = try? Data(contentsOf: url) else { return nil }
        let options: [String: Any] = [kSecImportExportPassphrase as String: passphrase]
        var items: CFArray?
        guard SecPKCS12Import(data as CFData, options as CFDictionary, &items) == errSecSuccess,
              let arr = items as? [[String: Any]],
              let first = arr.first,
              let raw = first[kSecImportItemIdentity as String]
        else { return nil }
        return (raw as! SecIdentity)
    }

    static func certificate(of identity: SecIdentity) -> SecCertificate? {
        var cert: SecCertificate?
        guard SecIdentityCopyCertificate(identity, &cert) == errSecSuccess else { return nil }
        return cert
    }

    /// Minimal big-endian (modulus, exponent) of an RSA public key, matching
    /// the byte encoding the pairing hash expects (no DER sign byte).
    static func rsaPublicKeyParts(of certificate: SecCertificate) -> (modulus: Data, exponent: Data)? {
        guard let key = SecCertificateCopyKey(certificate),
              let ext = SecKeyCopyExternalRepresentation(key, nil) as Data?
        else { return nil }
        return parsePKCS1(ext)
    }

    /// Parses a PKCS#1 RSAPublicKey: SEQUENCE { INTEGER modulus, INTEGER exponent }.
    private static func parsePKCS1(_ der: Data) -> (modulus: Data, exponent: Data)? {
        var idx = der.startIndex
        func readByte() -> UInt8? {
            guard idx < der.endIndex else { return nil }
            defer { idx = der.index(after: idx) }
            return der[idx]
        }
        func readLength() -> Int? {
            guard let first = readByte() else { return nil }
            if first & 0x80 == 0 { return Int(first) }
            let count = Int(first & 0x7F)
            var len = 0
            for _ in 0..<count {
                guard let b = readByte() else { return nil }
                len = (len << 8) | Int(b)
            }
            return len
        }
        func readInteger() -> Data? {
            guard let tag = readByte(), tag == 0x02, let len = readLength() else { return nil }
            let end = der.index(idx, offsetBy: len, limitedBy: der.endIndex) ?? der.endIndex
            var bytes = der[idx..<end]
            idx = end
            while bytes.first == 0x00 { bytes = bytes.dropFirst() }  // strip DER sign byte
            return Data(bytes)
        }
        guard let seqTag = readByte(), seqTag == 0x30, let _ = readLength() else { return nil }
        guard let modulus = readInteger(), let exponent = readInteger() else { return nil }
        return (modulus, exponent)
    }
}
