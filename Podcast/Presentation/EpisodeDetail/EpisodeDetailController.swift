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
    /// Save and download for this episode (the ••• menu reads and changes it).
    private lazy var actions = EpisodeActionViewModel(episode: episode)

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
        setupMoreButton()
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

    // MARK: - ••• (save, download, share)

    /// Top right, a system bar button: on iOS 26 it gets its Liquid Glass
    /// capsule, like the back button. Its menu is built each time it opens
    /// (EpisodeMenu), so it shows "Saved", the download's progress, or
    /// "Downloaded" as they are now.
    private func setupMoreButton() {
        let more = UIBarButtonItem(
            title: String(localized: "More"),
            image: UIImage(systemName: "ellipsis"),
            menu: EpisodeMenu.make { [weak self] in
                guard let self else { return [] }
                return EpisodeMenu.items(for: self.actions, onShare: { [weak self] in self?.share() })
            }
        )
        navigationItem.rightBarButtonItem = more
    }

    /// The share sheet with the episode's audio link, from the ••• button.
    private func share() {
        guard let url = URL(string: episode.streamUrl) else { return }
        let sheet = UIActivityViewController(activityItems: [episode.title, url], applicationActivities: nil)
        sheet.popoverPresentationController?.sourceItem = navigationItem.rightBarButtonItem
        present(sheet, animated: true)
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
