//
//  GenrePodcastsController.swift
//  Podcast
//

import UIKit
import SwiftUI

/// A category pushed from Search (GenreRankingView). The name is big in the
/// content, so the bar only has the back arrow.
final class GenrePodcastsController: UIViewController {

    private let viewModel: GenreRankingViewModel

    init(genre: Genre) {
        self.viewModel = GenreRankingViewModel(genre: genre)
        super.init(nibName: nil, bundle: nil)
        // For VoiceOver and the next screen's back button; hidden in the bar.
        title = genre.name
        navigationItem.titleView = UIView()
        navigationItem.largeTitleDisplayMode = .never
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorName.screenBackground.uiColor
        let ranking = GenreRankingView(
            viewModel: viewModel,
            onOpenPodcast: { [weak self] in self?.open($0) },
            onPlay: { PlayerManager.shared.play($0) }
        )
        embedFullScreen(UIHostingController(rootView: ranking))
    }

    private func open(_ podcast: Podcast) {
        RecentSearchesManager.shared.record(podcast)
        let episodes = EpisodesController()
        episodes.podcast = podcast
        navigationController?.pushViewController(episodes, animated: true)
    }
}
