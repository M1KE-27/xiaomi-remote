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

    static func parse(from data: Data) -> IncomingMessage? {
        guard data.count >= 2 else { return nil }
        let length = Int(data[0]) << 8 | Int(data[1])
        guard data.count >= 2 + length, length > 0 else { return nil }

        let payload = data.subdata(in: 2..<(2 + length))
        guard !payload.isEmpty else { return nil }

        let tagByte = payload[0]
        let fieldNumber = Int(tagByte >> 3)

        return IncomingMessage(fieldNumber: fieldNumber, payload: payload)
    }

    var isPingRequest: Bool { fieldNumber == 11 }
    var isConfigureResponse: Bool { fieldNumber == 2 }
    var isSetActiveResponse: Bool { fieldNumber == 7 }

    var pingVal1: UInt64 {
        guard payload.count > 1 else { return 0 }
        var nested = payload.dropFirst()
        guard !nested.isEmpty, nested[nested.startIndex] == 0x08 else { return 0 }
        nested = nested.dropFirst()
        var offset = nested.startIndex
        let asData = Data(nested)
        var idx = offset - asData.startIndex
        return Data.decodeVarint(from: asData, at: &idx) ?? 0
    }
}
