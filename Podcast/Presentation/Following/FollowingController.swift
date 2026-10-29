//
//  FollowingController.swift
//  Podcast
//

import UIKit
import SwiftUI

/// "Following", pushed from Home: the podcasts you follow. Back is the
/// standard one (button or edge swipe).
final class FollowingController: UIViewController {

    /// The followed shows' episodes, shared with Home (no second download).
    private let followingFeed: FollowingFeedViewModel

    init(followingFeed: FollowingFeedViewModel) {
        self.followingFeed = followingFeed
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Following")
        hideNavigationTitle()
        view.backgroundColor = ColorName.screenBackground.uiColor
        setupHosting()
    }

    private func setupHosting() {
        let list = FollowingListView(
            followingFeed: followingFeed,
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
