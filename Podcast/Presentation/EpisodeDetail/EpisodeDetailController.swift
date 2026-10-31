//
//  EpisodeDetailController.swift
//  Podcast
//

import UIKit
import SwiftUI

/// An episode, full screen (EpisodeDetailView). The navigation bar stays
/// clear, with no title: only the back button. Save, download and share
/// are on the page, under the artwork.
final class EpisodeDetailController: UIViewController, ZoomDismissible {

    private let viewModel: EpisodeDetailViewModel

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
        useClearNavigationBar()
        setupHosting()
    }

    private func setupHosting() {
        let page = EpisodeDetailView(
            viewModel: viewModel,
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
    }
}
