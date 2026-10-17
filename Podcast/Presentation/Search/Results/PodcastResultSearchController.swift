//
//  PodcastResultSearchController.swift
//  Podcast
//
//  Created by Jesus Mora on 05/05/26.
//
import UIKit

class PodcastResultSearchController: UIViewController {
    
    var viewModel: PodcastSearchViewModel
    
    private lazy var collectionView: UICollectionView = {
        let config = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.allowsSelection = true
        // Scrolling the results closes the keyboard, which brings the tab bar back.
        cv.keyboardDismissMode = .onDrag
        cv.allowsMultipleSelection = false
        return cv
    }()
    
    /// A row: the podcast and, in a category, its place in the ranking.
    private struct Row {
        let podcast: Podcast
        let rank: Int?
    }

    private let searchPodcastCellRegistration = UICollectionView.hostingListRegistration { (row: Row) in
        PodcastCellUI(podcast: row.podcast, rank: row.rank)
    }

    /// Numbers the rows (a category's ranking). Search results aren't numbered.
    private let showsRank: Bool

    init(viewModel: PodcastSearchViewModel, showsRank: Bool = false) {
        self.viewModel = viewModel
        self.showsRank = showsRank
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        clearCollectionViewSelection(collectionView, animated: true)
    }
    
    private func configure() {
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    /// What the list currently shows, to reload only on changes.
    private var renderedPodcastIDs: [Int] = []

    /// iOS 26: UIKit tracks `viewModel.podcasts` read here and calls this again
    /// when it changes (the new value is already stored, no extra hop).
    override func updateProperties() {
        super.updateProperties()
        let ids = viewModel.podcasts.map(\.trackId)
        guard ids != renderedPodcastIDs else { return }
        renderedPodcastIDs = ids
        collectionView.reloadData()
    }
}

// MARK: - DataSource

extension PodcastResultSearchController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.podcasts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let podcast = viewModel.podcasts[indexPath.item]
        return collectionView.dequeueConfiguredReusableCell(
            using: searchPodcastCellRegistration,
            for: indexPath,
            item: Row(podcast: podcast, rank: showsRank ? indexPath.item + 1 : nil)
        )
    }
}

// MARK: - Delegate

extension PodcastResultSearchController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let podcast = viewModel.podcasts[indexPath.item]
        RecentSearchesManager.shared.record(podcast)
        let episodesController = EpisodesController()
        episodesController.podcast = podcast
        navigationController?.pushViewController(episodesController, animated: true)
    }
}
