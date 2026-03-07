import Foundation
import CryptoKit

/// Bencode value types
enum BencodeValue {
    case integer(Int64)
    case data(Data)
    case list([BencodeValue])
    case dictionary([String: BencodeValue])

    var stringValue: String? {
        if case .data(let data) = self {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    var intValue: Int64? {
        if case .integer(let value) = self {
            return value
        }
        return nil
    }

    var listValue: [BencodeValue]? {
        if case .list(let value) = self {
            return value
        }
        return nil
    }

    var dictValue: [String: BencodeValue]? {
        if case .dictionary(let value) = self {
            return value
        }
        return nil
    }
}

/// Errors that can occur during parsing
enum BencodeError: Error {
    case invalidFormat
    case unexpectedEndOfData
    case invalidInteger
    case invalidStringLength
}

/// Parser for bencode format used in .torrent files
class BencodeParser {
    private var data: Data
    private var position: Int = 0

    init(data: Data) {
        self.data = data
    }

    /// Parse the bencode data and return the root value
    func parse() throws -> BencodeValue {
        return try parseValue()
    }

    private func parseValue() throws -> BencodeValue {
        guard position < data.count else {
            throw BencodeError.unexpectedEndOfData
        }

        let byte = data[position]

        switch byte {
        case UInt8(ascii: "i"):
            return try parseInteger()
        case UInt8(ascii: "l"):
            return try parseList()
        case UInt8(ascii: "d"):
            return try parseDictionary()
        case UInt8(ascii: "0")...UInt8(ascii: "9"):
            return try parseString()
        default:
            throw BencodeError.invalidFormat
        }
    }

    private func parseInteger() throws -> BencodeValue {
        position += 1 // skip 'i'

        var numStr = ""
        while position < data.count && data[position] != UInt8(ascii: "e") {
            numStr.append(Character(UnicodeScalar(data[position])))
            position += 1
        }

        guard position < data.count else {
            throw BencodeError.unexpectedEndOfData
        }

        position += 1 // skip 'e'

        guard let value = Int64(numStr) else {
            throw BencodeError.invalidInteger
        }

        return .integer(value)
    }

    private func parseString() throws -> BencodeValue {
        var lengthStr = ""
        while position < data.count && data[position] != UInt8(ascii: ":") {
            lengthStr.append(Character(UnicodeScalar(data[position])))
            position += 1
        }

        guard position < data.count else {
            throw BencodeError.unexpectedEndOfData
        }

        position += 1 // skip ':'

        guard let length = Int(lengthStr), length >= 0 else {
            throw BencodeError.invalidStringLength
        }

        guard position + length <= data.count else {
            throw BencodeError.unexpectedEndOfData
        }

        let stringData = data[position..<(position + length)]
        position += length

        return .data(Data(stringData))
    }

    private func parseList() throws -> BencodeValue {
        position += 1 // skip 'l'

        var items: [BencodeValue] = []

        while position < data.count && data[position] != UInt8(ascii: "e") {
            items.append(try parseValue())
        }

        guard position < data.count else {
            throw BencodeError.unexpectedEndOfData
        }

        position += 1 // skip 'e'

        return .list(items)
    }

    private func parseDictionary() throws -> BencodeValue {
        position += 1 // skip 'd'

        var dict: [String: BencodeValue] = [:]

        while position < data.count && data[position] != UInt8(ascii: "e") {
            let keyValue = try parseString()
            guard case .data(let keyData) = keyValue,
                  let key = String(data: keyData, encoding: .utf8) else {
                throw BencodeError.invalidFormat
            }
            dict[key] = try parseValue()
        }

        guard position < data.count else {
            throw BencodeError.unexpectedEndOfData
        }

        position += 1 // skip 'e'

        return .dictionary(dict)
    }
}

/// Parser specifically for .torrent files
class TorrentParser {

    /// Parse a .torrent file and return a TorrentFile struct
    static func parse(from url: URL) throws -> TorrentFile {
        let data = try Data(contentsOf: url)
        return try parse(data: data)
    }

    static func parse(data: Data) throws -> TorrentFile {
        let parser = BencodeParser(data: data)
        let root = try parser.parse()

        guard case .dictionary(let rootDict) = root else {
            throw BencodeError.invalidFormat
        }

        // Extract info dictionary
        guard let infoValue = rootDict["info"],
              case .dictionary(let info) = infoValue else {
            throw BencodeError.invalidFormat
        }

        // Get torrent name
        let name = info["name"]?.stringValue ?? "Unknown"

        // Get files
        var files: [TorrentFileEntry] = []
        var totalSize: Int64 = 0

        if let filesValue = info["files"]?.listValue {
            // Multi-file torrent
            for fileValue in filesValue {
                guard case .dictionary(let fileDict) = fileValue else { continue }

                let size = fileDict["length"]?.intValue ?? 0
                var pathComponents: [String] = []

                if let pathList = fileDict["path"]?.listValue {
                    for pathPart in pathList {
                        if let pathStr = pathPart.stringValue {
                            pathComponents.append(pathStr)
                        }
                    }
                }

                files.append(TorrentFileEntry(path: pathComponents, size: size))
                totalSize += size
            }
        } else if let length = info["length"]?.intValue {
            // Single-file torrent
            files.append(TorrentFileEntry(path: [name], size: length))
            totalSize = length
        }

        // Get trackers
        var trackers: [String] = []

        if let announce = rootDict["announce"]?.stringValue {
            trackers.append(announce)
        }

        if let announceList = rootDict["announce-list"]?.listValue {
            for tier in announceList {
                if let tierList = tier.listValue {
                    for tracker in tierList {
                        if let url = tracker.stringValue, !trackers.contains(url) {
                            trackers.append(url)
                        }
                    }
                }
            }
        }

        // Get creation date
        var creationDate: Date?
        if let timestamp = rootDict["creation date"]?.intValue {
            creationDate = Date(timeIntervalSince1970: TimeInterval(timestamp))
        }

        // Get optional fields
        let comment = rootDict["comment"]?.stringValue
        let createdBy = rootDict["created by"]?.stringValue

        // Get piece info
        let pieceLength = info["piece length"]?.intValue ?? 0
        var pieceCount = 0
        if case .data(let piecesData) = info["pieces"] {
            pieceCount = piecesData.count / 20 // SHA1 hashes are 20 bytes
        }

        // Check if private
        let isPrivate = info["private"]?.intValue == 1

        // Calculate info hash
        let infoHash = calculateInfoHash(from: data, rootDict: rootDict)

        return TorrentFile(
            name: name,
            files: files,
            totalSize: totalSize,
            trackers: trackers,
            creationDate: creationDate,
            comment: comment,
            createdBy: createdBy,
            pieceLength: Int(pieceLength),
            pieceCount: pieceCount,
            infoHash: infoHash,
            isPrivate: isPrivate
        )
    }

    /// Calculate the SHA1 hash of the info dictionary (used as torrent identifier)
    private static func calculateInfoHash(from data: Data, rootDict: [String: BencodeValue]) -> String? {
        // Find the info dictionary in the raw data and hash it
        // This is a simplified approach - we re-encode the info dict
        guard let infoValue = rootDict["info"] else { return nil }

        if let encoded = encodeValue(infoValue) {
            let hash = Insecure.SHA1.hash(data: encoded)
            return hash.map { String(format: "%02x", $0) }.joined()
        }
        return nil
    }

    /// Re-encode a bencode value to Data
    private static func encodeValue(_ value: BencodeValue) -> Data? {
        var result = Data()

        switch value {
        case .integer(let num):
            result.append(contentsOf: "i\(num)e".utf8)

        case .data(let data):
            result.append(contentsOf: "\(data.count):".utf8)
            result.append(data)

        case .list(let items):
            result.append(contentsOf: "l".utf8)
            for item in items {
                guard let encoded = encodeValue(item) else { return nil }
                result.append(encoded)
            }
            result.append(contentsOf: "e".utf8)

        case .dictionary(let dict):
            result.append(contentsOf: "d".utf8)
            // Keys must be sorted
            for key in dict.keys.sorted() {
                result.append(contentsOf: "\(key.utf8.count):".utf8)
                result.append(contentsOf: key.utf8)
                guard let encoded = encodeValue(dict[key]!) else { return nil }
                result.append(encoded)
            }
            result.append(contentsOf: "e".utf8)
        }

        return result
    }
}
