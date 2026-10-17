//
//  DownloadEpisodeViewController.swift
//  Podcast
//
//  Created by Jesus Mora on 30/01/26.
//

import UIKit
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

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCellRegistration()
        configureCollection()
        
        view.backgroundColor = ColorName.screenBackground.uiColor
        collectionView.backgroundColor = .clear

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    
    private var renderedEpisodeIDs: [String] = []

    /// iOS 26: UIKit tracks `viewModel.episode` read here and calls this again
    /// when it changes. (Each cell's play/pause state updates by itself:
    /// UIHostingConfiguration tracks its own reads.)
    override func updateProperties() {
        super.updateProperties()
        let ids = viewModel.episode.map(\.streamUrl)
        guard ids != renderedEpisodeIDs else { return }
        renderedEpisodeIDs = ids
        collectionView.reloadData()
    }

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
