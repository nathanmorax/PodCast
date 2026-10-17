//
//  EpisodesController.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import UIKit
import SwiftUI

private enum Layout {
    /// First guess only: the header measures itself (it grows with "Read more").
    static let estimatedHeaderHeight: CGFloat = 640
    /// The cover part of the header (EpisodeHeaderView's hero). Past it, the
    /// navigation bar becomes solid and shows the podcast's name.
    static let heroHeight: CGFloat = 420
    /// Every row is exactly this tall. Fixed on purpose: with self-sizing rows
    /// the real heights only became known while scrolling, and each
    /// correction moved the rows (worst when scrolling back up).
    static let cellHeight: CGFloat = 172
    static let spacing: CGFloat = 8
}

class EpisodesController: UIViewController {

    private let perf = PerformanceLogger.scroll

    private var lastHeaderState: HeaderState?
    private var headerActions = EpisodeHeaderActions()
    private let headerStretch = HeaderStretch()
    private var eventsTaks: Task<Void, Never>?

    var podcast: Podcast? {
        didSet {
            // One request: episodes and the description come from the same feed.
            loadEpisodes()
        }
    }

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: Self.makeLayout())
        cv.translatesAutoresizingMaskIntoConstraints = false
        // The cover goes all the way up, under the status bar and the
        // (transparent) navigation bar; the bottom inset is set by hand.
        cv.contentInsetAdjustmentBehavior = .never
        cv.delegate   = self
        cv.dataSource = self
        return cv
    }()

    private lazy var loaderView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .label
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var loaderContainerView: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .clear
        container.addSubview(loaderView)
        NSLayoutConstraint.activate([
            loaderView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            loaderView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: 200)
        ])
        return container
    }()

    private lazy var viewModel: EpisodesViewModel = {
        let remote = PodcastRemoteDataService()
        let repository = PodcastRepositoryImpl(remoteDataSource: remote)
        return EpisodesViewModel(repository: repository)
    }()

    /// Created in viewDidLoad, never lazily: UIKit crashes ("Attempted to
    /// dequeue a cell using a registration that was created inside
    /// -collectionView:cellForItemAtIndexPath:") if a registration is first
    /// made while a cell is being dequeued. A `lazy var` did exactly that.
    private var episodeCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Episode>!

    private func setupCellRegistration() {
        episodeCellRegistration = UICollectionView.hostingRegistration { [weak self] (episode: Episode) in
            EpisodeCell(viewModel: EpisodeActionViewModel(episode: episode)) {
                self?.showInfo(for: episode)
            }
        }
    }

    private var headerRegistration: UICollectionView.SupplementaryRegistration<HostingHeaderView>!

    /// Self-sizing rows and header.
    ///
    /// Before, a flow layout gave every row a fixed 164 pt and the header a
    /// fixed 720 pt, while their SwiftUI content had its own size: long titles
    /// or bigger text spilled into the next row (rows on top of each other),
    /// "Read more" made the header taller than its slot (covering the first
    /// episodes), and the hosted cells tried to resize themselves during the
    /// scroll (rows moving). Now each row and the header measure their content.
    private static func makeLayout() -> UICollectionViewCompositionalLayout {
        let size = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(Layout.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Layout.spacing
        section.contentInsets = NSDirectionalEdgeInsets(
            top: Layout.spacing, leading: Layout.spacing,
            bottom: Layout.spacing, trailing: Layout.spacing
        )

        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(Layout.estimatedHeaderHeight)
            ),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        // The cover goes edge to edge and under the status bar: insets are
        // never measured from the safe area, and the side insets are only
        // for the rows.
        section.contentInsetsReference = .none
        section.supplementaryContentInsetsReference = .none

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = .none
        return UICollectionViewCompositionalLayout(section: section, configuration: configuration)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        perf.measure("viewDidLoad") {
            setupCellRegistration()
            setupHeaderRegistration()
            setupCollectionView()
            listenerHeaderEvents()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCollectionViewInset()
        updateNavigationBar()
        refreshVisibleHeader()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateCollectionViewInset()
    }

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
        let threshold = Layout.heroHeight - view.safeAreaInsets.top - 60
        let collapsed = collectionView.contentOffset.y > threshold
        guard collapsed != isHeaderCollapsed || navigationItem.standardAppearance == nil else { return }
        isHeaderCollapsed = collapsed
        let appearance = collapsed ? solidBarAppearance : transparentBarAppearance
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.title = collapsed ? podcast?.trackName : nil
    }

    deinit {
        eventsTaks?.cancel()
    }

    // MARK: - Observation (iOS 26 automatic tracking)

    /// What the collection view currently shows, to reload only on changes.
    private var renderedEpisodeIDs: [String] = []

    /// UIKit tracks every @Observable value read here (loading flag, episodes,
    /// favorites, description) and calls this again, before the next layout,
    /// when any of them changes. Replaces three withObservationTracking loops.
    override func updateProperties() {
        super.updateProperties()

        if viewModel.isLoadingEpisodes {
            loaderView.startAnimating()
            loaderContainerView.isHidden = false
        } else {
            loaderView.stopAnimating()
            loaderContainerView.isHidden = true
        }

        let episodeIDs = viewModel.episodes.map(\.streamUrl)
        if episodeIDs != renderedEpisodeIDs {
            let previous = renderedEpisodeIDs
            renderedEpisodeIDs = episodeIDs
            applyEpisodes(episodeIDs, replacing: previous)
        }

        guard let podcast else { return }
        let headerState = HeaderState(
            isFavorite: viewModel.isFavorite(podcast),
            description: viewModel.podcastDescription,
            isLoadingDescription: viewModel.isLoadingDescription
        )
        if headerState != lastHeaderState {
            lastHeaderState = headerState
            refreshVisibleHeader()
        }
    }

    /// The next page (the old list plus more at the end) is *inserted*, so the
    /// rows on screen stay where they are. Before, every page did a full
    /// reloadData() in the middle of the scroll: all visible cells were
    /// rebuilt and the list visibly jumped.
    private func applyEpisodes(_ ids: [String], replacing previous: [String]) {
        let isNextPage = !previous.isEmpty
            && ids.count > previous.count
            && Array(ids.prefix(previous.count)) == previous
        guard isNextPage, collectionView.window != nil else {
            collectionView.reloadData()
            return
        }
        let newRows = (previous.count..<ids.count).map { IndexPath(item: $0, section: 0) }
        UIView.performWithoutAnimation {
            collectionView.insertItems(at: newRows)
        }
    }

    // MARK: - Setup

    private func updateCollectionViewInset() {
        // .never adjustment: add the bottom safe area (home indicator + the
        // space RootView reserves for the bar) ourselves. The top stays 0 so
        // the cover reaches the top of the screen.
        let bottom = view.safeAreaInsets.bottom
        collectionView.contentInset.bottom = bottom
        collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(
            top: view.safeAreaInsets.top, left: 0, bottom: bottom, right: 0
        )
    }


    private func setupCollectionView() {
        view.addSubview(collectionView)
        collectionView.addSubview(loaderContainerView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loaderContainerView.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: Layout.estimatedHeaderHeight),
            loaderContainerView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            loaderContainerView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            loaderContainerView.widthAnchor.constraint(equalTo: collectionView.widthAnchor)
        ])
    }

    private func setupHeaderRegistration() {
        headerRegistration = UICollectionView.SupplementaryRegistration<HostingHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, _ in
            guard let self, let podcast = self.podcast else { return }
            header.host(self.makeHeaderView(for: podcast), parent: self)
        }
    }

    private func makeHeaderView(for podcast: Podcast) -> EpisodeHeaderView {
        perf.measure("makeHeaderView") {
            EpisodeHeaderView(
                podcast: podcast,
                isFavorite: viewModel.isFavorite(podcast),
                podcastDescription: viewModel.podcastDescription,
                isLoadingDescription: viewModel.isLoadingDescription,
                actions: headerActions,
                stretch: headerStretch
            )
        }
    }

    // MARK: - Load

    fileprivate func loadEpisodes() {
        guard let feedUrl = podcast?.feedUrl else { return }
        viewModel.loadEpisodes(feedURL: feedUrl)
    }

    // MARK: - Header events

    func listenerHeaderEvents() {
        eventsTaks = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            for await event in self.headerActions.events {
                guard !Task.isCancelled else { break }
                switch event {
                case .play:     self.handlePlayPodcast()
                case .about:    self.showAbout()
                case .bookmark: self.handleFavoritePodcast()
                case .download: self.handleDownloadPodcast()
                }
            }
        }
    }

    // MARK: - Actions

    @objc fileprivate func handleFavoritePodcast() {
        guard let podcast else { return }
        viewModel.toggleFavorite(podcast: podcast)
    }

    /// "Listen to podcast": the newest episode by date (most feeds list it
    /// first, but not all).
    private func handlePlayPodcast() {
        guard let newest = viewModel.episodes.max(by: { $0.pubDate < $1.pubDate }) else { return }
        PlayerManager.shared.play(newest)
    }

    /// The podcast's full description in a sheet (the ⓘ next to it).
    private func showAbout() {
        guard let podcast else { return }
        let sheet = UIHostingController(rootView: PodcastAboutSheet(
            podcast: podcast,
            description: viewModel.podcastDescription ?? ""
        ))
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium(), .large()]
            presentation.prefersGrabberVisible = true
            presentation.preferredCornerRadius = 28
        }
        present(sheet, animated: true)
    }

    /// The episode's details in a sheet (half screen, can grow).
    private func showInfo(for episode: Episode) {
        let sheet = UIHostingController(rootView: EpisodeInfoSheet(episode: episode) { [weak self] in
            PlayerManager.shared.play(episode)
            self?.dismiss(animated: true)
        })
        if let presentation = sheet.sheetPresentationController {
            presentation.detents = [.medium(), .large()]
            presentation.prefersGrabberVisible = true
            presentation.preferredCornerRadius = 28
        }
        present(sheet, animated: true)
    }

    private func handleDownloadPodcast() {
        print("Download tapped")
    }

    private func refreshVisibleHeader() {
        guard let podcast else { return }
        let headerView = makeHeaderView(for: podcast)
        let kind = UICollectionView.elementKindSectionHeader

        for indexPath in collectionView.indexPathsForVisibleSupplementaryElements(ofKind: kind) {
            guard let header = collectionView.supplementaryView(forElementKind: kind, at: indexPath)
                    as? HostingHeaderView else { continue }
            header.host(headerView, parent: self)
        }
    }
}

// MARK: - DataSource

extension EpisodesController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.episodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        perf.measure("cellForItemAt") {
            let episode = viewModel.episodes[indexPath.item]
            return collectionView.dequeueConfiguredReusableCell(
                using: episodeCellRegistration,
                for: indexPath,
                item: episode
            )
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        perf.measure("viewForSupplementaryElement") {
            guard kind == UICollectionView.elementKindSectionHeader else { return UICollectionReusableView() }
            
            return collectionView.dequeueConfiguredReusableSupplementary(
                using: headerRegistration,
                for: indexPath
            )
        }
    }
}

// MARK: - Delegate

extension EpisodesController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let episode = viewModel.episodes[indexPath.row]
        PlayerManager.shared.play(episode)
    }
}

extension EpisodesController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigationBar()

        // Pulled past the top: the cover grows into the gap. Written only
        // when it changes, so normal scrolling doesn't touch the header.
        let pull = max(0, -scrollView.contentOffset.y)
        if headerStretch.pull != pull {
            headerStretch.pull = pull
        }
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height * 1.5 {
            viewModel.loadMoreEpisodes()
        }
    }
}
