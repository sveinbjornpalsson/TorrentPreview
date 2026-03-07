import SwiftUI

struct TorrentPreviewView: View {
    let torrent: TorrentFile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                headerSection

                Divider()

                // Summary
                summarySection

                Divider()

                // Files
                filesSection

                if !torrent.trackers.isEmpty {
                    Divider()
                    trackersSection
                }

                if hasMetadata {
                    Divider()
                    metadataSection
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(NSColor.textBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.zipper")
                .font(.system(size: 32))
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(torrent.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text("BitTorrent File")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)

            HStack(spacing: 24) {
                summaryItem(title: "Total Size", value: torrent.formattedSize)
                summaryItem(title: "Files", value: "\(torrent.files.count)")
                summaryItem(title: "Pieces", value: "\(torrent.pieceCount) x \(torrent.formattedPieceLength)")
                if torrent.isPrivate {
                    summaryItem(title: "Private", value: "Yes")
                }
            }
        }
    }

    private func summaryItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    // MARK: - Files

    private var filesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Files (\(torrent.files.count))")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(torrent.files.prefix(100).enumerated()), id: \.offset) { _, file in
                    fileRow(file: file)
                }

                if torrent.files.count > 100 {
                    Text("... and \(torrent.files.count - 100) more files")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func fileRow(file: TorrentFileEntry) -> some View {
        HStack {
            Image(systemName: iconForFile(file.fullPath))
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(file.fullPath)
                .font(.system(.subheadline, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func iconForFile(_ path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()

        switch ext {
        case "mp4", "mkv", "avi", "mov", "wmv", "flv", "webm", "m4v":
            return "film"
        case "mp3", "flac", "wav", "aac", "ogg", "m4a", "wma":
            return "music.note"
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp":
            return "photo"
        case "pdf":
            return "doc.text"
        case "zip", "rar", "7z", "tar", "gz":
            return "archivebox"
        case "txt", "md", "nfo":
            return "doc.plaintext"
        case "srt", "sub", "ass":
            return "captions.bubble"
        default:
            return "doc"
        }
    }

    // MARK: - Trackers

    private var trackersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trackers (\(torrent.trackers.count))")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(torrent.trackers.prefix(10).enumerated()), id: \.offset) { _, tracker in
                    Text(tracker)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                if torrent.trackers.count > 10 {
                    Text("... and \(torrent.trackers.count - 10) more trackers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Metadata

    private var hasMetadata: Bool {
        torrent.creationDate != nil || torrent.comment != nil || torrent.createdBy != nil || torrent.infoHash != nil
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Metadata")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                if let date = torrent.creationDate {
                    metadataRow(title: "Created", value: formatDate(date))
                }

                if let createdBy = torrent.createdBy {
                    metadataRow(title: "Created By", value: createdBy)
                }

                if let comment = torrent.comment, !comment.isEmpty {
                    metadataRow(title: "Comment", value: comment)
                }

                if let hash = torrent.infoHash {
                    metadataRow(title: "Info Hash", value: hash)
                }
            }
        }
    }

    private func metadataRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.system(.subheadline, design: title == "Info Hash" ? .monospaced : .default))
                .lineLimit(3)
                .textSelection(.enabled)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Error View

struct TorrentErrorView: View {
    let error: Error

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Unable to Parse Torrent")
                .font(.title2)
                .fontWeight(.semibold)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.textBackgroundColor))
    }
}
