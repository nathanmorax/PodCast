//
//  PodcastSearchContainerController.swift
//  Podcast
//
//  Created by Nathan Mora on 08/11/23.
//

import UIKit

/// The Search screen. It has no search bar of its own: the field lives in the
/// bottom bar (right above the keyboard while typing) and its text arrives
/// through `AppNavigator.searchQuery`. Empty → categories; text → results.
class PodcastSearchContainerController: UIViewController {

    /// Set when the bar's search field opens this screen: the keyboard comes
    /// up as soon as it's visible.
    var focusesSearchOnAppear = false

    private let navigator: AppNavigator
    private let genreController = PodcastGenreController()

    private lazy var viewModel: PodcastSearchViewModel = {
        let remote = PodcastRemoteDataService()
        let repository = PodcastRepositoryImpl(remoteDataSource: remote)
        return PodcastSearchViewModel(repository: repository)
    }()

    private lazy var resultsController: PodcastResultSearchController = {
        PodcastResultSearchController(viewModel: self.viewModel)
    }()

    init(navigator: AppNavigator = .shared) {
        self.navigator = navigator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Search")
        showTitleOnLeading()
        view.backgroundColor = ColorName.screenBackground.uiColor
        setupCloseButton()

        setupChildControllers()
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
        // Leaving with the keyboard up must not leave the bar in typing mode.
        navigator.isSearching = false
    }

    /// ⌄ at the top right: closes Search (it goes back down). The bottom bar
    /// keeps only the search field.
    private func setupCloseButton() {
        let close = UIBarButtonItem(
            image: UIImage(systemName: "chevron.down"),
            primaryAction: UIAction { [weak self] _ in self?.navigator.closeSearch() }
        )
        close.accessibilityLabel = String(localized: "Close search")
        navigationItem.rightBarButtonItem = close
    }

    /// Brings up the keyboard on the bar's search field.
    func focusSearchField() {
        navigator.isSearching = true
    }

    // MARK: - Query

    /// The query the screen is showing, to react only to changes.
    private var appliedQuery: String?

    /// iOS 26: UIKit tracks `navigator.searchQuery` read here and calls this
    /// again whenever the bar's field changes.
    override func updateProperties() {
        super.updateProperties()
        let query = navigator.searchQuery
        guard query != appliedQuery else { return }
        appliedQuery = query
        apply(query: query)
    }

    private func apply(query: String) {
        // Always forward the text: an empty string cancels a pending search.
        viewModel.search(query)
        if query.isEmpty {
            showGenres()
        } else {
            showResults()
        }
    }

    // MARK: - Setup

    private func setupChildControllers() {
        // A category opens its own screen: its name centered, with back.
        genreController.onSelectGenre = { [weak self] genre in
            self?.navigationController?.pushViewController(GenrePodcastsController(genre: genre), animated: true)
        }

        for child in [genreController, resultsController] as [UIViewController] {
            addChild(child)
            view.addSubview(child.view)
            child.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                child.view.topAnchor.constraint(equalTo: view.topAnchor),
                child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            child.didMove(toParent: self)
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
