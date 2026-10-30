//
//  EpisodeDetailController.swift
//  Podcast
//

import UIKit
import SwiftUI

/// An episode, full screen (EpisodeDetailView). The navigation bar is clear
/// over the artwork and turns solid, with the title in tall capitals, once
/// the artwork scrolls away. Save, download and share are on the page,
/// under the artwork, so the bar only has the back button.
final class EpisodeDetailController: UIViewController, ZoomDismissible {

    private let viewModel: EpisodeDetailViewModel
    private let headerPull = HeaderPull()

    /// - Parameter podcast: the show, when known: "From the show" and
    ///   "More from…" need it.
    init(episode: Episode, podcast: Podcast?) {
        self.viewModel = EpisodeDetailViewModel(episode: episode, podcast: podcast)
        super.init(nibName: nil, bundle: nil)
        title = episode.title
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
            viewModel: viewModel,
            pull: headerPull,
            onOpenPodcast: { [weak self] podcast in
                self?.pushZooming(EpisodesController(podcast: podcast), from: .podcast(podcast.id))
            },
            onOpenEpisode: { [weak self] episode in
                guard let self else { return }
                navigationController?.pushViewController(
                    EpisodeDetailController(episode: episode, podcast: viewModel.podcast),
                    animated: true
                )
            },
            onScroll: { [weak self] offset in self?.didScroll(to: offset) }
        )
        embedFullScreen(UIHostingController(rootView: page))
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

    /// The title in the bar, once the artwork (and its title) is gone.
    private lazy var collapsedTitle: UILabel = {
        let label = UILabel()
        let base = UIFont.systemFont(ofSize: 18, weight: .bold, width: .compressed)
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: base, maximumPointSize: 24)
        label.adjustsFontForContentSizeCategory = true
        label.text = viewModel.episode.title.uppercased()
        label.textColor = ColorName.ink.uiColor
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private func updateNavigationBar(offset: CGFloat) {
        let threshold = EpisodeHero.height - view.safeAreaInsets.top - 60
        let collapsed = offset > threshold
        guard collapsed != isCollapsed else { return }
        isCollapsed = collapsed
        let appearance = collapsed ? solidAppearance : transparentAppearance
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.titleView = collapsed ? collapsedTitle : UIView()
    }
}
