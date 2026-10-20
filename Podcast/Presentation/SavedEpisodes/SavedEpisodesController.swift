//
//  SavedEpisodesController.swift
//  Podcast
//

import UIKit
import SwiftUI

/// Favorites or Downloads, pushed from Library (SavedEpisodesView).
final class SavedEpisodesController: UIViewController {

    private let collection: SavedEpisodesView.Collection

    init(_ collection: SavedEpisodesView.Collection) {
        self.collection = collection
        super.init(nibName: nil, bundle: nil)
        switch collection {
        case .favorites: title = String(localized: "Favorites")
        case .downloads: title = String(localized: "Downloads")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorName.screenBackground.uiColor
        let list = SavedEpisodesView(collection: collection) { [weak self] episode in
            // Outside a podcast page, an episode opens full screen.
            self?.navigationController?.pushViewController(
                EpisodeDetailController(episode: episode, podcastName: nil),
                animated: true
            )
        }
        embedFullScreen(UIHostingController(rootView: list))
    }
}
