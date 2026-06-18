import Foundation

enum KeyDirection: Int {
    case startLong = 1   // RemoteDirection.START_LONG
    case endLong = 2     // RemoteDirection.END_LONG
    case short = 3       // RemoteDirection.SHORT  (un tap normal va con 3, no 0)
}

// Números de campo según remotemessage.proto (Android TV Remote v2):
// RemoteMessage { remote_configure=1, remote_set_active=2, remote_ping_request=8,
//                 remote_ping_response=9, remote_key_inject=10 }
enum TVMessage {

    /// Se envía COMO RESPUESTA al remote_configure del TV.  RemoteMessage.remote_configure = 1
    static func configureResponse() -> Data {
        var msg = ProtobufEncoder()
        msg.putMessage(1) { configure in            // remote_configure
            configure.putVarint(1, value: 622)       // code1
            configure.putMessage(2) { dev in         // device_info = 2
                dev.putString(1, value: "iPhone")                   // model
                dev.putString(2, value: "Apple")                    // vendor
                dev.putVarint(3, value: 1)                          // unknown1
                dev.putString(4, value: "1")                        // unknown2
                dev.putString(5, value: "com.local.xiaomiremote")   // package_name
                dev.putString(6, value: "1.0.0")                    // app_version
            }
        }
        return msg.build().withLengthPrefix()
    }

    /// RemoteMessage.remote_set_active = 2
    static func setActive() -> Data {
        var msg = ProtobufEncoder()
        msg.putMessage(2) { active in
            active.putVarint(1, value: 622)          // active
        }
        return msg.build().withLengthPrefix()
    }

    /// RemoteMessage.remote_key_inject = 10  ·  RemoteKeyInject { key_code=1, direction=2 }
    static func keyInject(keyCode: Int, direction: KeyDirection = .short) -> Data {
        var msg = ProtobufEncoder()
        msg.putMessage(10) { ki in
            ki.putVarint(1, value: UInt64(keyCode))            // key_code
            ki.putVarint(2, value: UInt64(direction.rawValue)) // direction
        }
        return msg.build().withLengthPrefix()
    }

    /// RemoteMessage.remote_app_link_launch_request = 90 · { app_link = 1 }
    static func appLink(_ link: String) -> Data {
        var msg = ProtobufEncoder()
        msg.putMessage(90) { req in
            req.putString(1, value: link)
        }
        return msg.build().withLengthPrefix()
    }

    /// RemoteMessage.remote_ping_response = 9
    static func pingResponse(val1: UInt64) -> Data {
        var msg = ProtobufEncoder()
        msg.putMessage(9) { ping in
            ping.putVarint(1, value: val1)
        }
        return msg.build().withLengthPrefix()
    }
}

struct IncomingMessage {
    let fieldNumber: Int
    let payload: Data

    /// `payload` is a single de-framed protobuf message (length prefix already removed).
    init(payload: Data) {
        self.payload = payload
        if let first = payload.first {
            self.fieldNumber = Int(first >> 3)
        } else {
            self.fieldNumber = 0
        }
    }

    var isConfigureRequest: Bool { fieldNumber == 1 }  // TV nos envía remote_configure
    var isSetActive: Bool { fieldNumber == 2 }
    var isPingRequest: Bool { fieldNumber == 8 }       // remote_ping_request

    var pingVal1: UInt64 {
        guard payload.count > 1 else { return 0 }
        let base = payload.startIndex
        // field 11 (ping) is a nested message: tag, length, then field 1 varint (0x08).
        var offset = 1
        guard let _ = Data.decodeVarint(from: payload, at: &offset) else { return 0 }
        guard offset < payload.count, payload[base + offset] == 0x08 else { return 0 }
        offset += 1
        return Data.decodeVarint(from: payload, at: &offset) ?? 0
    }
}
