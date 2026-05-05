//
//  PodcastSearchController.swift
//  Podcast
//
//  Created by Nathan Mora on 08/11/23.
//

import UIKit
import Alamofire
import Combine

class PodcastSearchContainerController: UIViewController {
    let searchController = UISearchController(searchResultsController: nil)
    
    private let genreController = PodcastGenreController()
    private var cancellables = Set<AnyCancellable>()

    
    private lazy var viewModel: PodcastSearchViewModel = {
        let remote = PodcastRemoteDataService()
        let repository = PodcastRepositoryImpl(remoteDataSource: remote)
        return PodcastSearchViewModel(repository: repository)
    }()
    
    private lazy var resultsController: PodcastResultSearchController = {
        return PodcastResultSearchController(viewModel: self.viewModel)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupSearchBar()
        self.setupChildControllers()
        self.showGenres()
        
    }
    
    private func setupBindings() {
        viewModel.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { errorMessage in
                print(errorMessage)
            }
            .store(in: &cancellables)
    }

    
    private func setupSearchBar() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search Podcasts"
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func setupChildControllers() {
        
        addChild(genreController)
        view.addSubview(genreController.view)
        genreController.view.translatesAutoresizingMaskIntoConstraints = false
        genreController.didMove(toParent: self)
        
        addChild(resultsController)
        view.addSubview(resultsController.view)
        resultsController.view.translatesAutoresizingMaskIntoConstraints = false
        resultsController.didMove(toParent: self)
        
        for childView in [genreController.view, resultsController.view].compactMap({ $0 }) {
            NSLayoutConstraint.activate([
                childView.topAnchor.constraint(equalTo: view.topAnchor),
                childView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                childView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                childView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
    
    
    private func showGenres() {
        genreController.view.isHidden = false
        resultsController.view.isHidden = true
    }
    
    private func showResults() {
        genreController.view.isHidden = true
        resultsController.view.isHidden = false
    }
    
}

extension PodcastSearchContainerController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText.isEmpty{
            showGenres()
        } else {
            showResults()
            viewModel.searchText.send(searchText)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        showGenres()
    }
}

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

import UIKit

extension UIViewController {
    func clearCollectionViewSelection(_ collectionView: UICollectionView, animated: Bool) {
        guard let selected = collectionView.indexPathsForSelectedItems,
              !selected.isEmpty else { return }
        
        guard let coordinator = transitionCoordinator else {
            selected.forEach { collectionView.deselectItem(at: $0, animated: animated) }
            return
        }
        
        coordinator.animate { _ in
            selected.forEach { collectionView.deselectItem(at: $0, animated: true) }
        } completion: { context in
            if context.isCancelled {
                selected.forEach {
                    collectionView.selectItem(at: $0, animated: false, scrollPosition: [])
                }
            }
        }
    }
}
