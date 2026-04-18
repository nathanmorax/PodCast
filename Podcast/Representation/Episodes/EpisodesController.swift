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

class EpisodesController: UIViewController {
    fileprivate let cellId = "cellId"
    private let headerView = EpisodeHeaderView()
    private let statusBarBackgroundView = UIView()
    
    private var cancellables = Set<AnyCancellable>()
    
    private enum Layout {
        static let headerHeight: CGFloat   = 160
        static let cellHeight: CGFloat     = 120
        static let sectionInset            = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    var podcast: Podcast? {
        didSet {
            loadEpisodes()
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
//        cv.backgroundColor = .clear
        cv.delegate   = self
        cv.dataSource = self
        return cv
    }()
    
    private lazy var viewModel: EpisodesViewModel = {
        let remote = PodcastRemoteDataService()
        let repository = PodcastRepositoryImpl(remoteDataSource: remote)
        return EpisodesViewModel(repository: repository)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCollectionView()
        self.setupNavigationButtons()
        self.setupBindings()
        self.configureCollectionViewAppearance()
        
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCollectionViewInset()
    }

    private func updateCollectionViewInset() {
        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
        collectionView.contentInset.bottom = tabBarHeight
        collectionView.verticalScrollIndicatorInsets.bottom = tabBarHeight
    }
    
    fileprivate func setupNavigationButtons() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "heart"),
                            style: .plain,
                            target: self,
                            action: #selector(handleFavoritePodcast)
                           )
        ]
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
    
    private func setupBindings() {
        viewModel.$episodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
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
                self?.updateFavoriteButton()
            }
            .store(in: &cancellables)
        
    }
    
    fileprivate func loadEpisodes() {
        
        guard let feedUrl =  podcast?.feedUrl else { return }
        viewModel.loadEpisodes(feedURL: feedUrl)
    }
    // MARK: - SetupWork
    
    private func configureCollectionViewAppearance() {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellId)
        
        collectionView.register(
            EpisodeHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: EpisodeHeaderView.idIdentifierEpisodeHeader
        )
    }
    
    
    @objc fileprivate func handleFavoritePodcast() {
        print("Saving info into UserDeafults")
        
        guard let podcast = podcast else { return }
        
        viewModel.toggleFavorite(podcast: podcast)

    }
    
    private func updateFavoriteButton() {
        
        guard let podcast = podcast else { return }
        
        let isFavorite = viewModel.isFavorite(podcast)
        let imageName = isFavorite ? "heart.fill" : "heart"
        
        navigationItem.rightBarButtonItem?.image = UIImage(systemName: imageName)
        
    }
    
    
}

extension EpisodesController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.episodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: cellId,
            for: indexPath
        ) as? EpisodeCell else { return UICollectionViewCell() }
        
        cell.episode = viewModel.episodes[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: EpisodeHeaderView.idIdentifierEpisodeHeader,
                for: indexPath
              ) as? EpisodeHeaderView
                
        else { return UICollectionReusableView() }
        
        header.configure(with: podcast)
        return header
    }
}
extension EpisodesController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let episode = viewModel.episodes[indexPath.row]
        PlayerManager.shared.play(episode: episode)
    }
}

extension EpisodesController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: Layout.cellHeight)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: Layout.headerHeight)
    }
}
