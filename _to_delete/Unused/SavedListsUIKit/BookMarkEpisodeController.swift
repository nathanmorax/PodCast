//
//  BookMarkEpisodeController.swift
//  Podcast
//
//  Created by Jesus Mora on 30/01/26.
//

import UIKit
import SwiftUI

class BookMarkEpisodeController: UIViewController {
    
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
    
    private let viewModel = BookMarkEpisodeViewModel()
    
    private var savedEpisodeCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, Episode>!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Favorites")
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

    /// iOS 26: UIKit tracks `viewModel.episodes` read here and calls this again
    /// when it changes.
    override func updateProperties() {
        super.updateProperties()
        let ids = viewModel.episodes.map(\.streamUrl)
        guard ids != renderedEpisodeIDs else { return }
        renderedEpisodeIDs = ids
        collectionView.reloadData()
    }

    // Playback state (play/pause icon) is NOT observed here on purpose:
    // BookMarkView reads `viewModel.isPlaying` inside its body, and
    // UIHostingConfiguration tracks @Observable reads, so each cell
    // refreshes itself without reloading the collection view.

    
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


extension BookMarkEpisodeController: UICollectionViewDataSource, UICollectionViewDelegate {
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

    /// Outside a podcast page, an episode opens full screen.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let episode = viewModel.episodes[indexPath.item]
        let detail = EpisodeDetailController(episode: episode, podcastName: nil)
        navigationController?.pushViewController(detail, animated: true)
    }
}
