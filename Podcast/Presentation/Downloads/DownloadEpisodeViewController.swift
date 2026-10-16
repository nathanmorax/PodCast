//
//  DownloadEpisodeViewController.swift
//  Podcast
//
//  Created by Jesus Mora on 30/01/26.
//

import UIKit
import Combine
import SwiftUI

class DownloadEpisodeViewController: UIViewController {
    
    private var pendingDeleteIndexPath: IndexPath?
    
    private lazy var collectionView: UICollectionView = {
        // Same spacing/insets as before, but each row now sizes to its content.
        let layout = UICollectionViewCompositionalLayout.selfSizingList(
            spacing: 24,
            contentInsets: NSDirectionalEdgeInsets(top: 42, leading: 4, bottom: 16, trailing: 4)
        )
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return cv
    }()
    
    private let viewModel = DownloadEpisodeViewModel()
    
    private var savedEpisodeCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Episode>!

    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCellRegistration()
        configureCollection()
        observeEpisodes()
//        observePlayback()
        
        view.backgroundColor = AppColor.slateGray.uiColor
        collectionView.backgroundColor = .clear

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    
    private func observeEpisodes() {
        withObservationTracking {
            _ = viewModel.episode
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.collectionView.reloadData()
                self?.observeEpisodes()
            }
        }
    }

//    private func observePlayback() {
//        withObservationTracking {
//            _ = PlayerManager.shared.viewModel.isPlaying
//            _ = PlayerManager.shared.currentEpisode
//        } onChange: { [weak self] in
//            DispatchQueue.main.async {
//                self?.observePlayback()
//            }
//        }
//    }
    
    private func reloadVisibleCells() {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        visibleIndexPaths.forEach { indexPath in
            collectionView.reloadItems(at: [indexPath])
        }
    }

    
    private func configureCellRegistration() {
          savedEpisodeCellRegistration = UICollectionView.hostingRegistration(backgroundStyle: .none) { (episode: Episode) in
              DownloadEpisodeRowView(viewModel: EpisodeActionViewModel(episode: episode))
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


extension DownloadEpisodeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.episode.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let episode = viewModel.episode[indexPath.item]

        return collectionView.dequeueConfiguredReusableCell(
            using: savedEpisodeCellRegistration,
            for: indexPath,
            item: episode
        )
    }
    
}
