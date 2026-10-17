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
            onSearch: { AppNavigator.shared.showSearch() },
            onOpenFollowing: { [weak self] in
                self?.navigationController?.pushViewController(FollowingController(), animated: true)
            },
            onOpenFavorites: { [weak self] in
                self?.navigationController?.pushViewController(BookMarkEpisodeController(), animated: true)
            },
            onOpenDownloads: { [weak self] in
                self?.navigationController?.pushViewController(DownloadEpisodeViewController(), animated: true)
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

    private func open(_ podcast: Podcast) {
        let episodes = EpisodesController()
        episodes.podcast = podcast
        navigationController?.pushViewController(episodes, animated: true)
    }
}
