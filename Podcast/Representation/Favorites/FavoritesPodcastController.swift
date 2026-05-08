//
//  FavoritesPodcastController.swift
//  Podcast
//
//  Created by Jesus Mora on 30/01/26.
//

import UIKit
import Combine
import SwiftUI

class FavoritesPodcastController: UIViewController {
    
    private var pendingDeleteIndexPath: IndexPath?
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return cv
    }()
    
    private let viewModel = FavoritesViewModel(favoritesManager: .shared)
    
    private let favoritesPodcastCellRegistration = UICollectionView.hostingRegistration(backgroundStyle: .none) { (podcast: Podcast) in
        FavoritesPodcastCellUI(podcast: podcast)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureCollection()
        self.bindViewModel()
        
        view.backgroundColor = AppColor.slateGray.uiColor
        collectionView.backgroundColor = .clear

    }
    
    fileprivate func bindViewModel() {
        viewModel.$favorites
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] favorites in
                self?.collectionView.reloadData()
            })
            .store(in: &cancellables)
    }
    
    func configureCollection() {
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        
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
        return viewModel.favorites.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = viewModel.favorites[indexPath.item]
        return collectionView.dequeueConfiguredReusableCell(
            using: favoritesPodcastCellRegistration,
            for: indexPath,
            item: item)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let episodesController = EpisodesController()
        let podcast = self.viewModel.favorites[indexPath.item]
        episodesController.podcast = podcast
        navigationController?.pushViewController(episodesController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = (view.frame.width - 3 * 16) / 2
        
        return CGSize(width: width, height: width + 42)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 42, left: 16, bottom: 16, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        
        let selectedPodcast = viewModel.favorites[indexPath.item]
        
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
                self.pendingDeleteIndexPath = indexPath
                self.viewModel.remove(selectedPodcast)
            }
            
            return UIMenu(title: "", children: [playNext, markPlayed, delete])
        }
    }
}
