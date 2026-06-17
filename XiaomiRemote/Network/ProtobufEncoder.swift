import Foundation

struct ProtobufEncoder {
    private var data = Data()

    mutating func putVarint(_ fieldNumber: Int, value: UInt64) {
        writeRawVarint(UInt64(fieldNumber << 3 | 0))
        writeRawVarint(value)
    }

    mutating func putInt(_ fieldNumber: Int, value: Int) {
        putVarint(fieldNumber, value: UInt64(bitPattern: Int64(value)))
    }

    mutating func putString(_ fieldNumber: Int, value: String) {
        guard let bytes = value.data(using: .utf8) else { return }
        putLengthDelimited(fieldNumber, bytes: bytes)
    }

    mutating func putLengthDelimited(_ fieldNumber: Int, bytes: Data) {
        writeRawVarint(UInt64(fieldNumber << 3 | 2))
        writeRawVarint(UInt64(bytes.count))
        data.append(bytes)
    }

    mutating func putMessage(_ fieldNumber: Int, builder: (inout ProtobufEncoder) -> Void) {
        var nested = ProtobufEncoder()
        builder(&nested)
        putLengthDelimited(fieldNumber, bytes: nested.build())
    }

    private mutating func writeRawVarint(_ value: UInt64) {
        var v = value
        repeat {
            var byte = UInt8(v & 0x7F)
            v >>= 7
            if v != 0 { byte |= 0x80 }
            data.append(byte)
        } while v != 0
    }

    func build() -> Data { data }
}

extension Data {
    func withLengthPrefix() -> Data {
        var result = Data(count: 2)
        let len = UInt16(count)
        result[0] = UInt8(len >> 8)
        result[1] = UInt8(len & 0xFF)
        result.append(self)
        return result
    }

    static func decodeVarint(from data: Data, at offset: inout Int) -> UInt64? {
        var result: UInt64 = 0
        var shift = 0
        while offset < data.count {
            let byte = data[offset]
            offset += 1
            result |= UInt64(byte & 0x7F) << shift
            if byte & 0x80 == 0 { return result }
            shift += 7
            if shift >= 64 { return nil }
        }
        return nil
    }
}
