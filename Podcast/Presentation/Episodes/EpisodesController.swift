//
//  EpisodesController.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import UIKit
import SwiftUI

/// A podcast's page: the cover, "Listen to podcast" and its episodes.
///
/// The page itself is SwiftUI (PodcastEpisodesView). It used to be a
/// UICollectionView with SwiftUI cells: UIKit decided each row's size while
/// SwiftUI decided its content, and every time they disagreed rows drew over
/// each other or jumped while scrolling. A LazyVStack measures and places its
/// rows itself, so there's nothing left to disagree. This controller keeps
/// the UIKit parts: the navigation bar over the cover, the sheets, and the
/// header's actions.
final class EpisodesController: UIViewController, ZoomDismissible {

    /// Set in `init(podcast:)`. Changing it later (already on screen)
    /// reloads the feed.
    var podcast: Podcast? {
        didSet {
            // Inside an initializer Swift doesn't call didSet, so the first
            // load happens in viewDidLoad; this one is for later changes.
            if isViewLoaded { loadEpisodes() }
        }
    }

    convenience init(podcast: Podcast) {
        self.init()
        self.podcast = podcast
    }

    private let headerActions = EpisodeHeaderActions()
    private var eventsTask: Task<Void, Never>?
    private var hosting: UIHostingController<PodcastEpisodesView>?

    private lazy var viewModel: EpisodesViewModel = {
        let remote = PodcastRemoteDataService()
        let repository = PodcastRepositoryImpl(remoteDataSource: remote)
        return EpisodesViewModel(repository: repository)
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorName.screenBackground.uiColor
        setupPage()
        listenToHeaderEvents()
        // One request: episodes and the description come from the same feed.
        loadEpisodes()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationBar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        learnInterestIfListened()
    }

    /// Played something from this podcast? Its genre joins the listener's
    /// interests, so Home's "For you" learns from what they actually hear.
    private func learnInterestIfListened() {
        guard let current = PlayerManager.shared.currentEpisode,
              viewModel.episodes.contains(where: { $0.streamUrl == current.streamUrl }),
              let genreID = Genre.catalogID(forITunesGenre: podcast?.primaryGenreName) else { return }
        InterestsManager.shared.learn(genreID: genreID)
    }

    deinit {
        eventsTask?.cancel()
    }

    private func setupPage() {
        guard let podcast else { return }
        let page = PodcastEpisodesView(
            podcast: podcast,
            viewModel: viewModel,
            actions: headerActions,
            onScroll: { [weak self] offset in self?.didScroll(to: offset) },
            onShowInfo: { [weak self] episode in self?.showInfo(for: episode) },
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
        self.hosting = hosting
    }

    private func loadEpisodes() {
        guard let feedUrl = podcast?.feedUrl else { return }
        viewModel.loadEpisodes(feedURL: feedUrl)
    }

    // MARK: - Scroll

    private var scrollOffset: CGFloat = 0

    private func didScroll(to offset: CGFloat) {
        scrollOffset = offset
        updateNavigationBar()
    }

    // MARK: - Drag down to close (pushZooming)

    /// At the top (or pulled past it): dragging down closes the page.
    var isScrolledToTop: Bool { scrollOffset <= 1 }

    // MARK: - Navigation bar over the cover

    private var isHeaderCollapsed = false

    private lazy var transparentBarAppearance: UINavigationBarAppearance = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        return appearance
    }()

    private lazy var solidBarAppearance: UINavigationBarAppearance = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        return appearance
    }()

    /// Transparent over the cover; solid with the podcast's name once the
    /// cover has scrolled away.
    private func updateNavigationBar() {
        let collapsed = scrollOffset > EpisodeHeaderView.nameScrollsAwayAt
        guard collapsed != isHeaderCollapsed || navigationItem.standardAppearance == nil else { return }
        isHeaderCollapsed = collapsed
        let appearance = collapsed ? solidBarAppearance : transparentBarAppearance
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.title = collapsed ? podcast?.trackName : nil
    }

    // MARK: - Header events

    private func listenToHeaderEvents() {
        eventsTask = Task { [weak self] in
            guard let events = self?.headerActions.events else { return }
            for await event in events {
                guard let self, !Task.isCancelled else { break }
                switch event {
                case .play:     self.playNewest()
                case .about:    self.showAbout()
                case .follow:   self.toggleFavorite()
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleFavorite() {
        guard let podcast else { return }
        viewModel.toggleFavorite(podcast: podcast)
    }

    /// "Listen to podcast": the newest episode by date (most feeds list it
    /// first, but not all).
    private func playNewest() {
        guard let newest = viewModel.episodes.max(by: { $0.pubDate < $1.pubDate }) else { return }
        PlayerManager.shared.play(newest)
    }

    /// The podcast's full description in a sheet (the ⓘ in the header).
    private func showAbout() {
        guard let podcast else { return }
        presentSheet(PodcastAboutSheet(
            podcast: podcast,
            description: viewModel.podcastDescription ?? ""
        ))
    }

    /// An episode, full screen (tapping its row, or "Details" in its •••
    /// menu): pushed, with its artwork edge to edge.
    private func showInfo(for episode: Episode) {
        presentSheet(EpisodeInfoSheet(episode: episode) { [weak self] in
            PlayerManager.shared.play(episode)
            self?.dismiss(animated: true)
        })
    }

    /// Half screen, can grow to full.
    private func presentSheet<Content: View>(_ content: Content) {
        let sheet = UIHostingController(rootView: content)
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium(), .large()]
            presentation.prefersGrabberVisible = true
            presentation.preferredCornerRadius = 28
        }
        present(sheet, animated: true)
    }
}
