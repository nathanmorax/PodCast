//
//  FavoritesPodcastController.swift
//  Podcast
//
//  Created by Jesus Mora on 30/01/26.
//

import UIKit

class FavoritesPodcastController: UIViewController {
            
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
        super.viewWillAppear(animated)
        loadPodcastfavorites()
    }
    
    func loadPodcastfavorites() {
        viewModel.podcast = viewModel.fecthFavorites()
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
        return viewModel.podcast.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FavoritesPodcastCell.favoritesPodcastCellId, for: indexPath)
        
        if let cell = cell as? FavoritesPodcastCell {
            let podcast = self.viewModel.podcast[indexPath.row]
            cell.configureData(with: podcast)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
                
        let episodesController = EpisodesController()
        let podcast = self.viewModel.podcast[indexPath.item]
        episodesController.podcast = podcast
        navigationController?.pushViewController(episodesController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = (view.frame.width - 3 * 16) / 2
        
        return CGSize(width: width, height: width + 42)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int ) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        
        let selectedPodcast = viewModel.podcast[indexPath.item]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            
            guard let self = self else { return nil }
            
            let playNext = UIAction(
                title: "Reproducir a continuación",
                image: UIImage(systemName: "text.insert")
            ) { _ in
                print("Play next: \(selectedPodcast.trackName ?? "")")
            }
            
            let markPlayed = UIAction(
                title: "Marcar como reproducido",
                image: UIImage(systemName: "checkmark")
            ) { _ in
                print("Mark played")
            }
            
            let delete = UIAction(
                title: "Eliminar de favoritos",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                let removedPodcast = self.viewModel.podcast[indexPath.item]

                self.viewModel.removeFavorite(removedPodcast)
                
                self.viewModel.podcast.remove(at: indexPath.item)
                
                self.collectionView.performBatchUpdates {
                    self.collectionView.deleteItems(at: [indexPath])
                }
            }
            
            return UIMenu(title: "", children: [playNext, markPlayed, delete])
        }
    }
}
