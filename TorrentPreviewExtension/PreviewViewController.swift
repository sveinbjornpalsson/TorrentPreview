import Cocoa
import Quartz
import SwiftUI

class PreviewViewController: NSViewController, QLPreviewingController {

    override var nibName: NSNib.Name? {
        return nil
    }

    override func loadView() {
        self.view = NSView()
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        do {
            let torrent = try TorrentParser.parse(from: url)
            let previewView = TorrentPreviewView(torrent: torrent)
            let hostingView = NSHostingView(rootView: previewView)
            hostingView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(hostingView)

            NSLayoutConstraint.activate([
                hostingView.topAnchor.constraint(equalTo: view.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])

            handler(nil)
        } catch {
            let errorView = TorrentErrorView(error: error)
            let hostingView = NSHostingView(rootView: errorView)
            hostingView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(hostingView)

            NSLayoutConstraint.activate([
                hostingView.topAnchor.constraint(equalTo: view.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])

            handler(nil) // Show error view instead of failing
        }
    }
}
