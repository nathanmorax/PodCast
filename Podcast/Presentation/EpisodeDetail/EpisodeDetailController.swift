//
//  EpisodeDetailController.swift
//  Podcast
//

import UIKit
import SwiftUI

/// An episode, full screen (pushed when you tap an episode in a podcast's
/// list). Like the podcast page: the navigation bar is clear over the
/// artwork and turns solid, with the episode's title, once it scrolls away;
/// no bottom bar.
final class EpisodeDetailController: UIViewController, ZoomDismissible {

    private let episode: Episode
    private let podcastName: String?
    private let headerPull = HeaderPull()

    init(episode: Episode, podcastName: String?) {
        self.episode = episode
        self.podcastName = podcastName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorName.screenBackground.uiColor
        navigationItem.largeTitleDisplayMode = .never
        setupHosting()
        updateNavigationBar(offset: 0)
    }

    private func setupHosting() {
        let page = EpisodeDetailView(
            episode: episode,
            podcastName: podcastName,
            pull: headerPull,
            onPlay: { [episode] in PlayerManager.shared.play(episode) },
            onScroll: { [weak self] offset in self?.didScroll(to: offset) }
        )
        let hosting = UIHostingController(rootView: page)
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

    // MARK: - Scroll

    /// At the top (or pulled past it): dragging down closes the page
    /// (pushZooming).
    var isScrolledToTop: Bool { scrollOffset <= 1 }
    private var scrollOffset: CGFloat = 0

    private func didScroll(to offset: CGFloat) {
        scrollOffset = offset
        // Pulled past the top: the artwork stays pinned to the top.
        let pull = max(0, -offset)
        if headerPull.distance != pull {
            headerPull.distance = pull
        }
        updateNavigationBar(offset: offset)
    }

    // MARK: - Navigation bar over the artwork

    private var isCollapsed: Bool?

    private lazy var transparentAppearance: UINavigationBarAppearance = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        return appearance
    }()

    private lazy var solidAppearance: UINavigationBarAppearance = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        return appearance
    }()

    private func updateNavigationBar(offset: CGFloat) {
        let threshold = EpisodeDetailView.heroHeight - view.safeAreaInsets.top - 60
        let collapsed = offset > threshold
        guard collapsed != isCollapsed else { return }
        isCollapsed = collapsed
        let appearance = collapsed ? solidAppearance : transparentAppearance
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.title = collapsed ? episode.title : nil
    }
}
