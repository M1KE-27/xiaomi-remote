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
    /// Android TV Remote v2 frames each message with a protobuf varint length prefix.
    func withLengthPrefix() -> Data {
        var result = Data()
        var len = UInt64(count)
        repeat {
            var byte = UInt8(len & 0x7F)
            len >>= 7
            if len != 0 { byte |= 0x80 }
            result.append(byte)
        } while len != 0
        result.append(self)
        return result
    }

    static func decodeVarint(from data: Data, at offset: inout Int) -> UInt64? {
        var result: UInt64 = 0
        var shift = 0
        let base = data.startIndex
        while offset < data.count {
            let byte = data[base + offset]
            offset += 1
            result |= UInt64(byte & 0x7F) << shift
            if byte & 0x80 == 0 { return result }
            shift += 7
            if shift >= 64 { return nil }
        }
        return nil
    }

    /// Pulls one complete varint-length-prefixed message off the front of `buffer`.
    /// Returns the message payload (without prefix) and removes it from `buffer`.
    /// Returns nil if a full frame is not yet available.
    static func nextFrame(from buffer: inout Data) -> Data? {
        guard !buffer.isEmpty else { return nil }
        var offset = 0
        guard let length = decodeVarint(from: buffer, at: &offset) else { return nil }
        let total = offset + Int(length)
        guard buffer.count >= total else { return nil }
        let start = buffer.startIndex
        let payload = buffer.subdata(in: (start + offset)..<(start + total))
        buffer.removeSubrange(start..<(start + total))
        return payload
    }

    /// Reads a top-level varint field (e.g. status) from a protobuf message. Returns nil if absent.
    func protobufVarintField(_ fieldNumber: Int) -> UInt64? {
        var offset = 0
        while offset < count {
            guard let tag = Data.decodeVarint(from: self, at: &offset) else { return nil }
            let field = Int(tag >> 3)
            let wire = Int(tag & 0x7)
            switch wire {
            case 0:
                guard let v = Data.decodeVarint(from: self, at: &offset) else { return nil }
                if field == fieldNumber { return v }
            case 2:
                guard let len = Data.decodeVarint(from: self, at: &offset) else { return nil }
                offset += Int(len)
            case 5: offset += 4
            case 1: offset += 8
            default: return nil
            }
        }
        return nil
    }
}
