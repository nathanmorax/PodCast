//
//  FollowingController.swift
//  Podcast
//

import UIKit
import SwiftUI

/// "Following", pushed from Home: the podcasts you follow. Back is the
/// standard one (button or edge swipe).
final class FollowingController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Following")
        view.backgroundColor = ColorName.screenBackground.uiColor
        setupHosting()
    }

    private func setupHosting() {
        let list = FollowingListView(
            onOpenPodcast: { [weak self] podcast in self?.open(podcast) }
        )
        let hosting = UIHostingController(rootView: list)
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
        pushZooming(EpisodesController(podcast: podcast), from: .podcast(podcast.id))
    }
}
