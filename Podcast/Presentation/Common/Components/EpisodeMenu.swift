//
//  EpisodeMenu.swift
//  Podcast
//

import UIKit

/// The actions on one episode, as a UIKit menu: the ••• of a row and the
/// ••• at the top of the episode's page show the same items.
///
/// Built when it opens (UIDeferredMenuElement.uncached), not when its
/// button was made, so it always matches the episode now: downloading,
/// downloaded, saved…
@MainActor
enum EpisodeMenu {

    /// A menu whose items are asked for each time it opens.
    static func make(_ items: @escaping @MainActor () -> [UIMenuElement]) -> UIMenu {
        UIMenu(children: [
            UIDeferredMenuElement.uncached { completion in
                MainActor.assumeIsolated {
                    completion(items())
                }
            }
        ])
    }

    /// Details (when given) · Save · Download (whatever fits its state) ·
    /// Share (when given).
    static func items(for actions: EpisodeActionViewModel,
                      onInfo: (() -> Void)? = nil,
                      onShare: (() -> Void)? = nil) -> [UIMenuElement] {
        var items: [UIMenuElement] = []
        if let onInfo {
            items.append(UIAction(title: String(localized: "Details"),
                                  image: UIImage(systemName: "info.circle")) { _ in onInfo() })
        }
        items.append(saveAction(actions))
        items.append(downloadAction(actions))
        if let onShare {
            items.append(UIAction(title: String(localized: "Share"),
                                  image: UIImage(systemName: "square.and.arrow.up")) { _ in onShare() })
        }
        return items
    }

    /// Outlined while not saved; filled (and named "Saved") once it is.
    private static func saveAction(_ actions: EpisodeActionViewModel) -> UIAction {
        let saved = actions.isBookmarked
        return UIAction(
            title: saved ? String(localized: "Saved") : String(localized: "Save"),
            subtitle: saved ? String(localized: "Tap to remove") : nil,
            image: UIImage(systemName: saved ? "bookmark.fill" : "bookmark")
        ) { [weak actions] _ in
            actions?.toggleBookmark()
        }
    }

    /// What Download does depends on where the download is.
    private static func downloadAction(_ actions: EpisodeActionViewModel) -> UIAction {
        switch actions.downloadState {
        case .idle:
            return UIAction(title: String(localized: "Download"),
                            image: UIImage(systemName: "arrow.down.circle")) { [weak actions] _ in
                actions?.download()
            }
        case .failed:
            return UIAction(title: String(localized: "Retry download"),
                            image: UIImage(systemName: "arrow.clockwise.circle")) { [weak actions] _ in
                actions?.download()
            }
        case .waiting:
            return UIAction(title: String(localized: "Cancel download"),
                            image: UIImage(systemName: "stop.circle")) { [weak actions] _ in
                actions?.cancelDownload()
            }
        case .downloading(let progress):
            return UIAction(title: String(localized: "Cancel download"),
                            subtitle: progress.formatted(.percent.precision(.fractionLength(0))),
                            image: UIImage(systemName: "stop.circle")) { [weak actions] _ in
                actions?.cancelDownload()
            }
        case .downloaded:
            // Says what it does: removes the file (the episode stays).
            return UIAction(title: String(localized: "Remove download"),
                            image: UIImage(systemName: "trash"),
                            attributes: .destructive) { [weak actions] _ in
                actions?.deleteDownload()
            }
        }
    }
}
