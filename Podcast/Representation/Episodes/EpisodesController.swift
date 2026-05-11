//
//  EpisodesController.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import UIKit
import FeedKit
import SDWebImage
import Combine
import SwiftUI

class EpisodesController: UIViewController {
    fileprivate let cellId = "cellId"
    private var cancellables = Set<AnyCancellable>()
    
    private enum Layout {
        static let headerHeight: CGFloat = 720
        static let cellHeight: CGFloat   = 120
        static let sectionInset          = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
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
    
    private lazy var viewModel: EpisodesViewModel = {
        let remote = PodcastRemoteDataService()
        let repository = PodcastRepositoryImpl(remoteDataSource: remote)
        return EpisodesViewModel(repository: repository)
    }()
    
    private let episodeCellRegistration = UICollectionView.hostingRegistration { (episode: Episode) in
        EpisodeCellUI(episode: episode)
    }
    
    private var headerRegistration: UICollectionView.SupplementaryRegistration<HostingHeaderView>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeaderRegistration()
        setupCollectionView()
        setupBindings()
        configureCollectionViewAppearance()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCollectionViewInset()
        refreshVisibleHeader()
    }
    
    private func updateCollectionViewInset() {
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
        collectionView.contentInset.bottom = tabBarHeight
        collectionView.verticalScrollIndicatorInsets.bottom = tabBarHeight
    }
    
    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
    
    private func makeHeaderView(for podcast: Podcast) -> EpisodeHeaderViewUI {
        EpisodeHeaderViewUI(
            podcast: podcast,
            isFavorite: viewModel.isFavorite(podcast),
            podcastDescription: viewModel.podcastDescription,
            isLoadingDescription: viewModel.isLoadingDescription,
            onPlay:     { [weak self] in self?.handlePlayPodcast() },
            onBookmark: { [weak self] in self?.handleFavoritePodcast() },
            onDownload: { [weak self] in self?.handleDownloadPodcast() }
        )
    }
    
    private func setupBindings() {
        viewModel.$episodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.collectionView.reloadData()
                DispatchQueue.main.async {
                    self.refreshVisibleHeader()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { error in
                print("Episodes error:", error)
            }
            .store(in: &cancellables)
        
        viewModel.$favorites
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshVisibleHeader()
            }
            .store(in: &cancellables)
        
        viewModel.$podcastDescription
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshVisibleHeader()
            }
            .store(in: &cancellables)
        
        viewModel.$isLoadingDescription
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshVisibleHeader()
            }
            .store(in: &cancellables)
    }
    
    fileprivate func loadEpisodes() {
        guard let feedUrl = podcast?.feedUrl else { return }
        viewModel.loadEpisodes(feedURL: feedUrl)
    }
    
    private func configureCollectionViewAppearance() {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellId)
    }
    
    // MARK: - Actions
    
    @objc fileprivate func handleFavoritePodcast() {
        guard let podcast = podcast else { return }
        viewModel.toggleFavorite(podcast: podcast)
    }
    
    private func handlePlayPodcast() {
        guard let firstEpisode = viewModel.episodes.first else { return }
        PlayerManager.shared.play(episode: firstEpisode)
    }
    
    private func handleDownloadPodcast() {
        print("Download tapped")
    }
    
    private func refreshVisibleHeader() {
        guard let podcast = self.podcast else { return }
        let kind = UICollectionView.elementKindSectionHeader
        
        for indexPath in collectionView.indexPathsForVisibleSupplementaryElements(ofKind: kind) {
            guard let header = collectionView.supplementaryView(forElementKind: kind, at: indexPath)
                    as? HostingHeaderView else { continue }
            
            header.host(makeHeaderView(for: podcast))
        }
    }
}

// MARK: - DataSource

extension EpisodesController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.episodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let episode = viewModel.episodes[indexPath.item]
        return collectionView.dequeueConfiguredReusableCell(
            using: episodeCellRegistration,
            for: indexPath,
            item: episode)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }
        return collectionView.dequeueConfiguredReusableSupplementary(
            using: headerRegistration,
            for: indexPath
        )
    }
}

// MARK: - Delegate

extension EpisodesController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let episode = viewModel.episodes[indexPath.row]
        PlayerManager.shared.play(episode: episode)
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

// MARK: - HostingHeaderView

