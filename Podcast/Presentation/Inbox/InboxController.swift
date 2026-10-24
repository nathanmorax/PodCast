//
//  InboxController.swift
//  Podcast
//

import UIKit
import SwiftUI

/// The Inbox, pushed from the tray in Library (zooming out of it). Opening
/// it marks everything as seen: the tray's badge goes away, while this
/// visit still shows what was new.
final class InboxController: UIViewController {

    private let items: [ForYouViewModel.Item]
    private let newSince: Date

    init(items: [ForYouViewModel.Item], seen: InboxSeen = .shared) {
        self.items = items
        self.newSince = seen.lastSeen
        super.init(nibName: nil, bundle: nil)
        title = String(localized: "Inbox")
        seen.markSeen()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorName.screenBackground.uiColor
        let inbox = InboxView(items: items, newSince: newSince) { [weak self] item in
            // Outside a podcast page, an episode opens full screen.
            self?.navigationController?.pushViewController(
                EpisodeDetailController(episode: item.episode, podcastName: item.podcast.trackName),
                animated: true
            )
        }
        embedFullScreen(UIHostingController(rootView: inbox))
    }
}
