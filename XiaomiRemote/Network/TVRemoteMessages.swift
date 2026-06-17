import Foundation

enum KeyDirection: Int {
    case short = 0
    case startLong = 1
    case endLong = 2
}

enum TVMessage {

    static func configureRequest() -> Data {
        var msg = ProtobufEncoder()
        msg.putMessage(1) { configure in
            configure.putVarint(1, value: 622)
            configure.putMessage(6) { deviceInfo in
                deviceInfo.putVarint(1, value: 1)
                deviceInfo.putVarint(2, value: 3)
                deviceInfo.putString(4, value: "com.local.xiaomiremote")
                deviceInfo.putString(5, value: "1.0.0")
                deviceInfo.putString(6, value: "iPhone Remote")
            }
        }
        return msg.build().withLengthPrefix()
    }

    static func setActiveRequest() -> Data {
        var msg = ProtobufEncoder()
        msg.putMessage(6) { active in
            active.putVarint(1, value: 622)
        }
        return msg.build().withLengthPrefix()
    }

    static func keyInject(keyCode: Int, direction: KeyDirection = .short) -> Data {
        var msg = ProtobufEncoder()
        msg.putMessage(4) { keyInject in
            keyInject.putVarint(1, value: UInt64(direction.rawValue))
            keyInject.putVarint(2, value: UInt64(keyCode))
        }
        return msg.build().withLengthPrefix()
    }

    static func pingResponse(val1: UInt64) -> Data {
        var msg = ProtobufEncoder()
        msg.putMessage(12) { ping in
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

    var isPingRequest: Bool { fieldNumber == 11 }
    var isConfigureResponse: Bool { fieldNumber == 2 }
    var isSetActiveResponse: Bool { fieldNumber == 7 }

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
