//
//  EpisodesController.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import UIKit
import FeedKit
import SDWebImage

class EpisodesController: UIViewController {
    fileprivate let cellId = "cellId"
    private let headerView = EpisodeHeaderView()
    private let statusBarBackgroundView = UIView()
    
    
    
    private enum Layout {
        static let headerHeight: CGFloat   = 320
        static let cellHeight: CGFloat     = 120
        static let sectionInset            = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    var podcast: Podcast? {
        didSet {
            headerView.configure(with: podcast)
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
        cv.contentInsetAdjustmentBehavior = .never
        cv.backgroundColor = .systemBackground
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
        self.updateFavoriteButton()
        self.setupBindings()
        self.configureCollectionViewAppearance()
        
        edgesForExtendedLayout = [.top]
        extendedLayoutIncludesOpaqueBars = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFavoriteButton()
    }
    fileprivate func setupNavigationButtons() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "heart"),
                            style: .plain,
                            target: self,
                            action: #selector(handleFavoritePodcast)
            ),
            UIBarButtonItem(title: "Fetch",
                            style: .plain,
                            target: self,
                            action: #selector(handleFecthPodcast))
            
        ]
    }
    
    private func setupCollectionView() {
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        
        viewModel.onDataUpdated = { [weak self] in
            self?.collectionView.reloadData()
        }
        
        viewModel.onError = { error in
            print("Episodes error:", error)
        }
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
        updateFavoriteButton()
        print("✅ Saved with manager")
        
        
    }
    
    @objc fileprivate func handleFecthPodcast() {
        let favorites = viewModel.fecthFavorites()
        print("📦 Favorites:", favorites.map({ podcat in
            podcat.artistName
        }))
        
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
        (UIApplication.shared.keyWindow?.rootViewController as? MainTabController)?
            .maximizePlayerDetails(episode: episode)
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
