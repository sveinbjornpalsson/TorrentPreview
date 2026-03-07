import Foundation

/// Represents a single file entry in a torrent
struct TorrentFileEntry {
    let path: [String]  // Path components
    let size: Int64

    var fullPath: String {
        path.joined(separator: "/")
    }
}

/// Represents a parsed .torrent file
struct TorrentFile {
    let name: String
    let files: [TorrentFileEntry]
    let totalSize: Int64
    let trackers: [String]
    let creationDate: Date?
    let comment: String?
    let createdBy: String?
    let pieceLength: Int
    let pieceCount: Int
    let infoHash: String?
    let isPrivate: Bool

    /// Human-readable total size
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    /// Human-readable piece length
    var formattedPieceLength: String {
        ByteCountFormatter.string(fromByteCount: Int64(pieceLength), countStyle: .file)
    }
}
