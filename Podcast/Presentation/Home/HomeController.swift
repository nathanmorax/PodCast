//
//  HomeController.swift
//  Podcast
//

import UIKit
import SwiftUI

/// Root of the "Inicio" tab. Hosts HomeView and pushes the screens it opens.
/// The title is the native large title, like Biblioteca and Buscar.
final class HomeController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Library")
        showTitleOnLeading()
        navigationItem.largeTitleDisplayMode = .never
        // Same gray as the content, so the large title area doesn't show a
        // white band above it.
        view.backgroundColor = ColorName.screenBackground.uiColor
        setupHosting()
    }

    private func setupHosting() {
        let home = HomeView(
            onOpenPodcast: { [weak self] podcast in self?.open(podcast) },
            onOpenEpisode: { [weak self] episode, podcast in
                self?.pushZooming(
                    EpisodeDetailController(episode: episode, podcastName: podcast.trackName),
                    from: .episode(episode.streamUrl, section: .forYou)
                )
            },
            onOpenPlayedEpisode: { [weak self] episode in
                self?.pushZooming(
                    EpisodeDetailController(episode: episode, podcastName: nil),
                    from: .episode(episode.streamUrl, section: .recentlyPlayed)
                )
            },
            onSearch: { AppNavigator.shared.showSearch() },
            onOpenFollowing: { [weak self] in
                self?.pushZooming(FollowingController(), from: .collection(.following))
            },
            onOpenFavorites: { [weak self] in
                self?.pushZooming(SavedEpisodesController(.favorites), from: .collection(.favorites))
            },
            onOpenDownloads: { [weak self] in
                self?.pushZooming(SavedEpisodesController(.downloads), from: .collection(.downloads))
            }
        )
        let hosting = UIHostingController(rootView: home)
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

    /// Everything Home opens zooms out of its item and closes back into it
    /// (pushZooming): podcasts, episodes, and the collections.
    private func open(_ podcast: Podcast) {
        pushZooming(EpisodesController(podcast: podcast), from: .podcast(podcast.id))
    }
}
