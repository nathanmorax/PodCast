//
//  SearchResultsController.swift
//  Podcast
//

import UIKit
import SwiftUI

/// Search's results while typing (SearchResultsView). A child of
/// PodcastSearchContainerController, which decides what a tap opens.
final class SearchResultsController: UIViewController {

    var onOpenPodcast: ((Podcast) -> Void)?
    var onOpenEpisode: ((EpisodeSearchResult) -> Void)?

    private let viewModel: PodcastSearchViewModel

    init(viewModel: PodcastSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        let results = SearchResultsView(
            viewModel: viewModel,
            onOpenPodcast: { [weak self] in self?.onOpenPodcast?($0) },
            onOpenEpisode: { [weak self] in self?.onOpenEpisode?($0) }
        )
        embedFullScreen(UIHostingController(rootView: results))
    }
}
