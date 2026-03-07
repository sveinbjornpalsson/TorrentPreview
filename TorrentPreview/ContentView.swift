import SwiftUI

struct ContentView: View {
    @State private var extensionEnabled = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.zipper")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Torrent Preview")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("QuickLook extension for .torrent files")
                .font(.title3)
                .foregroundColor(.secondary)

            Divider()
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 12) {
                instructionRow(number: 1, text: "Keep this app in your Applications folder")
                instructionRow(number: 2, text: "Select a .torrent file in Finder")
                instructionRow(number: 3, text: "Press Space to preview")
            }
            .padding(.horizontal, 20)

            Divider()
                .padding(.horizontal, 40)

            VStack(spacing: 8) {
                Text("Troubleshooting")
                    .font(.headline)

                Text("If previews don't work, try running in Terminal:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("qlmanage -r")
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)

                Text("This resets QuickLook and reloads extensions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .frame(width: 450, height: 500)
    }

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.accentColor)
                .clipShape(Circle())

            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    ContentView()
}
