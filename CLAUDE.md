# Torrent Preview - Project Notes for Claude

## Environment

- **Xcode project**: `TorrentPreview.xcodeproj`
- **Bundle ID**: `com.sveinbjorn.TorrentPreview`

## Project Status

### Working Features
- .torrent file preview with file list, trackers, metadata
- Bencode parser
- File tree display with sizes
- Tracker list
- Creation date, comment, piece info

## QuickLook Extension Debugging

```bash
# Reset QuickLook cache
qlmanage -r

# Test preview
qlmanage -p /path/to/file.torrent

# List registered extensions
pluginkit -m -v -p com.apple.quicklook.preview
```

## Project Structure

```
TorrentPreview/
├── TorrentPreview.xcodeproj
├── TorrentPreview/                    # Main app target
│   ├── TorrentPreviewApp.swift
│   ├── ContentView.swift
│   ├── TorrentPreview.entitlements
│   └── Info.plist
├── TorrentPreviewExtension/           # QuickLook extension
│   ├── PreviewViewController.swift
│   ├── TorrentParser.swift
│   ├── TorrentPreviewView.swift
│   ├── TorrentPreviewExtension.entitlements
│   └── Info.plist
└── Shared/
    └── TorrentFile.swift
```

## Related Project

Font Preview is now a separate project at:
`/Users/sveinbjorn/Grams/torrent-preview/FontPreview/`
