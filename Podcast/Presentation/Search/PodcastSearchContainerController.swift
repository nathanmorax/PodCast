//
//  PodcastSearchContainerController.swift
//  Podcast
//
//  Created by Nathan Mora on 08/11/23.
//

import UIKit
import Alamofire

class PodcastSearchContainerController: UIViewController {
    let searchController = UISearchController(searchResultsController: nil)
    
    /// Set by AppNavigator when the search button opens this screen:
    /// the keyboard comes up right away.
    var focusesSearchOnAppear = false
    
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
        
        view.backgroundColor = AppColor.screenBackground.uiColor
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if focusesSearchOnAppear {
            focusesSearchOnAppear = false
            focusSearchField()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Leaving with the keyboard up must not keep the bottom bar hidden.
        AppNavigator.shared.isSearching = false
    }
    
    func focusSearchField() {
        searchController.isActive = true
        Task { @MainActor in
            self.searchController.searchBar.becomeFirstResponder()
        }
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
        searchController.searchBar.placeholder = "Buscar podcasts"
        title = "Buscar"
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        // Keep the field at the top, under the title (iOS 26 would otherwise
        // move it to a bottom toolbar, where our bottom bar lives).
        navigationItem.preferredSearchBarPlacement = .stacked
        navigationItem.searchBarPlacementAllowsToolbarIntegration = false
        definesPresentationContext = true
    }
    
    private func setupChildControllers() {
        
        // Tapping a category searches its name (until categories get their own
        // top-podcasts screen).
        genreController.onSelectGenre = { [weak self] genre in
            self?.search(for: genre.name)
        }
        
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
    
    
    /// Fills the field with `text` and shows its results.
    private func search(for text: String) {
        searchController.isActive = true
        searchController.searchBar.text = text
        viewModel.search(text)
        showResults()
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
    
    // Typing → the bottom bar steps aside. Keyboard gone (Cancel, Search key,
    // or scrolling the results) → it comes back.
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        AppNavigator.shared.isSearching = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        AppNavigator.shared.isSearching = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        showGenres()
    }
}
