//
//  PodcastResultSearchController.swift
//  Podcast
//
//  Created by Jesus Mora on 05/05/26.
//
import UIKit
import Combine

class PodcastResultSearchController: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    var viewModel: PodcastSearchViewModel
    
    private lazy var collectionView: UICollectionView = {
        let config = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.allowsSelection = true
        cv.allowsMultipleSelection = false
        return cv
    }()
    
    private let searchPodcastCellRegistration = UICollectionView.hostingListRegistration { (podcast: Podcast) in
        PodcastCellUI(podcast: podcast)
    }
    
    init(viewModel: PodcastSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        setupBindings()
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
    
    private func setupBindings() {
        viewModel.$podcasts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
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
            item: podcast
        )
    }
}

// MARK: - Delegate

extension PodcastResultSearchController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let podcast = viewModel.podcasts[indexPath.item]
        let episodesController = EpisodesController()
        episodesController.podcast = podcast
        navigationController?.pushViewController(episodesController, animated: true)
    }
}
