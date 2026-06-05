//
//  FavoritesPodcastController.swift
//  Podcast
//
//  Created by Jesus Mora on 30/01/26.
//

import UIKit
import Combine
import SwiftUI

class BookMarkEpisodeController: UIViewController {
    
    private var pendingDeleteIndexPath: IndexPath?
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return cv
    }()
    
    private let viewModel = BookMarkEpisodeViewModel()
    
    private var savedEpisodeCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Episode>!

    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCellRegistration()
        configureCollection()
        observeEpisodes()
        observePlayback()
        
        view.backgroundColor = AppColor.slateGray.uiColor
        collectionView.backgroundColor = .clear

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    
    private func observeEpisodes() {
        withObservationTracking {
            _ = viewModel.episodes
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
                self?.observeEpisodes()
            }
        }
    }

    private func observePlayback() {
        withObservationTracking {
            _ = PlayerManager.shared.viewModel.isPlaying
            _ = PlayerManager.shared.currentEpisode
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.observePlayback()
            }
        }
    }
    
    private func reloadVisibleCells() {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        visibleIndexPaths.forEach { indexPath in
            collectionView.reloadItems(at: [indexPath])
        }
    }

    
    private func configureCellRegistration() {
          savedEpisodeCellRegistration = UICollectionView.hostingRegistration(backgroundStyle: .none) { (episode: Episode) in
              BookMarkView(viewModel: EpisodeActionViewModel(episode: episode), state: .idle)
          }
      }
    
    private func configureCollection() {
        
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


extension BookMarkEpisodeController: UICollectionViewDataSource, UICollectionViewDelegate ,  UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.episodes.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let episode = viewModel.episodes[indexPath.item]

        return collectionView.dequeueConfiguredReusableCell(
            using: savedEpisodeCellRegistration,
            for: indexPath,
            item: episode
        )
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let horizontalInset: CGFloat = 4
        let width = collectionView.bounds.width - (horizontalInset * 2)

        return CGSize(width: width, height: 88)
    }
    
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        24
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 42, left: 0, bottom: 16, right: 0)
    }
    
}
