//
//  PodcastGenreController.swift
//  Podcast
//
//  Created by Jonathan Mora on 25/02/26.
//
import UIKit
import SwiftUI

/// What Search shows before you type (SearchExploreView): recent searches and
/// categories. A child of PodcastSearchContainerController.
final class PodcastGenreController: UIViewController {

    /// Tapping a category: the container searches its name.
    var onSelectGenre: ((Genre) -> Void)?

    private lazy var viewModel: GenresViewModel = {
        let remote = PodcastRemoteDataService()
        let repository = GenresRepositoryImpl(remoteDataSource: remote)
        return GenresViewModel(repository: repository)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupHosting()
        viewModel.loadGenre()
    }

    private func setupHosting() {
        let explore = SearchExploreView(
            genresViewModel: viewModel,
            onOpenPodcast: { [weak self] podcast in self?.open(podcast) },
            onSelectGenre: { [weak self] genre in self?.onSelectGenre?(genre) }
        )
        let hosting = UIHostingController(rootView: explore)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.backgroundColor = .clear
        addChild(hosting)
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
    }

    private func open(_ podcast: Podcast) {
        // Opening it again moves it to the front of the recent row.
        RecentSearchesManager.shared.record(podcast)
        let episodes = EpisodesController()
        episodes.podcast = podcast
        // A child of the search screen: this is Search's own stack.
        navigationController?.pushViewController(episodes, animated: true)
    }
}
