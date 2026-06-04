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
    static let cellHeight: CGFloat   = 120
    static let sectionInset          = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
}

class EpisodesController: UIViewController {

    private let perf = PerformanceLogger.scroll

    private var lastHeaderState: HeaderState?
    private var headerActions = EpisodeHeaderActions()
    private var eventsTaks: Task<Void, Never>?
    private var observationTask: Task<Void, Never>?   // ← reemplaza cancellables

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
        cv.contentInsetAdjustmentBehavior = .automatic
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
        EpisodeCell(episode: episode)
    }

    private var headerRegistration: UICollectionView.SupplementaryRegistration<HostingHeaderView>!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        perf.measure("viewDidLoad") {
            setupHeaderRegistration()
            setupCollectionView()
            observeViewModel()          // ← reemplaza setupBindings()
            listenerHeaderEvents()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCollectionViewInset()
        refreshVisibleHeader()
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
            DispatchQueue.main.async {
                guard let self else { return }
                if self.viewModel.isLoadingEpisodes {
                    self.loaderView.startAnimating()
                    self.loaderContainerView.isHidden = false
                } else {
                    self.loaderView.stopAnimating()
                    self.loaderContainerView.isHidden = true
                }
                self.observeLoading()   // re-observa para el siguiente cambio
            }
        }
    }

    private func observeEpisodes() {
        withObservationTracking {
            _ = viewModel.episodes
        } onChange: { [weak self] in
            DispatchQueue.main.async {
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
            DispatchQueue.main.async {
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
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
        collectionView.contentInset.bottom = tabBarHeight
        collectionView.verticalScrollIndicatorInsets.bottom = tabBarHeight
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
            supplementaryView.host(self.makeHeaderView(for: podcast))
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
            header.host(headerView)
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
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height * 1.5 {
            viewModel.loadMoreEpisodes()
        }
    }
}
