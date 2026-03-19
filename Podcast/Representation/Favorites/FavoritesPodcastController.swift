//
//  FavoritesPodcastController.swift
//  Podcast
//
//  Created by Jesus Mora on 30/01/26.
//


//55 6245 3562

import UIKit

class FavoritesPodcastController: UIViewController {
    
    private var podcast: [Podcast] = []
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return cv
    }()
    
    private let viewModel = EpisodesViewModel(
        repository: PodcastRepositoryImpl(
            remoteDataSource: PodcastRemoteDataService()
        )
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureCollection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadPodcastfavorites()
    }
    
    func loadPodcastfavorites() {
        podcast = viewModel.fecthFavorites()
        collectionView.reloadData()
    }
    
    func configureCollection() {
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(FavoritesPodcastCell.self, forCellWithReuseIdentifier: FavoritesPodcastCell.favoritesPodcastCellId)
        
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
    }
    
    
}


extension FavoritesPodcastController: UICollectionViewDataSource, UICollectionViewDelegate ,  UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return podcast.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FavoritesPodcastCell.favoritesPodcastCellId, for: indexPath)
        
        if let cell = cell as? FavoritesPodcastCell {
            let podcast = self.podcast[indexPath.row]
            cell.configureData(with: podcast)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = (view.frame.width - 3 * 16) / 2
        
        return CGSize(width: width, height: width + 42)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
}
