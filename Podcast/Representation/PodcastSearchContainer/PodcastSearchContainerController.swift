//
//  PodcastSearchController.swift
//  Podcast
//
//  Created by Nathan Mora on 08/11/23.
//

import UIKit
import Alamofire

class PodcastSearchContainerController: UIViewController {
    let searchController = UISearchController(searchResultsController: nil)
    
    private let genreController = PodcastGenreController()

    
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
        self.setupBindings()
        
        view.backgroundColor = AppColor.slateGray.uiColor
        
    }
    
    private func setupBindings() {
        withObservationTracking {
            _ = viewModel.error
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if let errorMessage = self.viewModel.error {
                    print(errorMessage)
                }
                self.setupBindings()
            }
        }
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
        
        // Always forward the text: an empty string cancels a pending search.
        viewModel.search(searchText)
        
        if searchText.isEmpty {
            showGenres()
        } else {
            showResults()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        showGenres()
    }
}
