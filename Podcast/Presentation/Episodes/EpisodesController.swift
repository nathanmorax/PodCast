//
//  EpisodesController.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import UIKit
import Combine
import SwiftUI

private enum Layout {
    static let headerHeight: CGFloat = 720
    /// The cover part of the header (EpisodeHeaderView's hero). Past it, the
    /// navigation bar becomes solid and shows the podcast's name.
    static let heroHeight: CGFloat = 420
    // Content needs ~160pt: date + 2-line title + 2-line description + 32pt button + 16pt padding.
    // At 150 the 100pt artwork + 36pt menu button column overflowed into the next row.
    static let cellHeight: CGFloat   = 164
    static let sectionInset          = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
}

class EpisodesController: UIViewController {

    private let perf = PerformanceLogger.scroll

    private var lastHeaderState: HeaderState?
    private var headerActions = EpisodeHeaderActions()
    private var eventsTaks: Task<Void, Never>?
    private var observationTask: Task<Void, Never>?

    var podcast: Podcast? {
        didSet {
            loadEpisodes()
            viewModel.loadPodcastDescription(feedURL: podcast?.feedUrl)
        }
    }

    private lazy var collectionView: UICollectionView = {
        let layout = StretchyHeaderLayout()
        layout.minimumLineSpacing      = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset            = Layout.sectionInset
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
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

    private let episodeCellRegistration = UICollectionView.hostingRegistration { (episode: Episode) in
        EpisodeCell(viewModel: EpisodeActionViewModel(episode: episode))
    }

    private var headerRegistration: UICollectionView.SupplementaryRegistration<HostingHeaderView>!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        perf.measure("viewDidLoad") {
            setupHeaderRegistration()
            setupCollectionView()
            observeViewModel()
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
        observationTask?.cancel()
    }

    // MARK: - Observation (reemplaza setupBindings con Combine)

    private func observeViewModel() {
        observeLoading()
        observeEpisodes()
        observeHeader()
    }

    private func observeLoading() {
        withObservationTracking {
            _ = viewModel.isLoadingEpisodes
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if self.viewModel.isLoadingEpisodes {
                    self.loaderView.startAnimating()
                    self.loaderContainerView.isHidden = false
                } else {
                    self.loaderView.stopAnimating()
                    self.loaderContainerView.isHidden = true
                }
                self.observeLoading()
            }
        }
    }

    private func observeEpisodes() {
        withObservationTracking {
            _ = viewModel.episodes
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if !self.viewModel.episodes.isEmpty {
                    self.collectionView.reloadData()
                    self.refreshVisibleHeader()
                }
                self.observeEpisodes()
            }
        }
    }

    private func observeHeader() {
        withObservationTracking {
            _ = viewModel.favorites
            _ = viewModel.podcastDescription
            _ = viewModel.isLoadingDescription
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self, let podcast = self.podcast else { return }
                self.perf.measure("favorites pipeline") {
                    let newState = HeaderState(
                        isFavorite: self.viewModel.isFavorite(podcast),
                        description: self.viewModel.podcastDescription,
                        isLoadingDescription: self.viewModel.isLoadingDescription
                    )
                    guard newState != self.lastHeaderState else { return }
                    self.lastHeaderState = newState
                    self.refreshVisibleHeader()
                }
                self.observeHeader()
            }
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

            loaderContainerView.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: Layout.headerHeight),
            loaderContainerView.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            loaderContainerView.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            loaderContainerView.widthAnchor.constraint(equalTo: collectionView.widthAnchor)
        ])
    }

    private func setupHeaderRegistration() {
        headerRegistration = UICollectionView.SupplementaryRegistration<HostingHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] supplementaryView, _, _ in
            guard let self, let podcast = self.podcast else { return }
            supplementaryView.host(self.makeHeaderView(for: podcast), parent: self)
        }
    }

    private func makeHeaderView(for podcast: Podcast) -> EpisodeHeaderView {
        perf.measure("makeHeaderView") {
            EpisodeHeaderView(
                podcast: podcast,
                isFavorite: viewModel.isFavorite(podcast),
                podcastDescription: viewModel.podcastDescription,
                isLoadingDescription: viewModel.isLoadingDescription,
                actions: headerActions
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

    private func handlePlayPodcast() {
        guard let firstEpisode = viewModel.episodes.first else { return }
        PlayerManager.shared.play(firstEpisode)
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

// MARK: - FlowLayout

extension EpisodesController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: Layout.cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: Layout.headerHeight)
    }
}

extension EpisodesController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateNavigationBar()
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height * 1.5 {
            viewModel.loadMoreEpisodes()
        }
    }
}
