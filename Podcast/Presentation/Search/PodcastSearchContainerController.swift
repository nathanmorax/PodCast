//
//  PodcastSearchContainerController.swift
//  Podcast
//
//  Created by Nathan Mora on 08/11/23.
//

import UIKit

/// The Search screen. It has no search bar of its own: the field lives in the
/// bottom bar (right above the keyboard while typing) and its text arrives
/// through `AppNavigator.searchQuery`. Empty → recents and categories
/// (SearchExploreController); text → podcasts and episodes
/// (SearchResultsController). It owns what every tap opens.
final class PodcastSearchContainerController: UIViewController {

    /// Set when the bar's search field opens this screen: the keyboard comes
    /// up as soon as it's visible.
    var focusesSearchOnAppear = false

    private let navigator: AppNavigator
    private let exploreController = SearchExploreController()

    private lazy var viewModel: PodcastSearchViewModel = {
        let remote = PodcastRemoteDataService()
        let repository = PodcastRepositoryImpl(remoteDataSource: remote)
        return PodcastSearchViewModel(repository: repository)
    }()

    private lazy var resultsController = SearchResultsController(viewModel: viewModel)

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
        exploreController.view.isHidden = !query.isEmpty
        resultsController.view.isHidden = query.isEmpty
    }

    // MARK: - Setup

    private func setupChildControllers() {
        exploreController.onOpenPodcast = { [weak self] in self?.open($0) }
        exploreController.onSelectGenre = { [weak self] in self?.open($0) }
        resultsController.onOpenPodcast = { [weak self] in self?.open($0) }
        resultsController.onOpenEpisode = { [weak self] in self?.open($0) }

        embedFullScreen(exploreController)
        embedFullScreen(resultsController)
    }

    // MARK: - Opening (Search's own stack)

    private func open(_ podcast: Podcast) {
        // Opening it again moves it to the front of "Recent".
        RecentSearchesManager.shared.record(podcast)
        pushZooming(EpisodesController(podcast: podcast), from: .podcast(podcast.id))
    }

    private func open(_ genre: Genre) {
        navigationController?.pushViewController(GenrePodcastsController(genre: genre), animated: true)
    }

    /// Tapping an episode row: its screen, like everywhere else (its ▶
    /// plays it instead). Search only knows the show's name, so the screen
    /// goes without "From the show".
    private func open(_ result: EpisodeSearchResult) {
        navigationController?.pushViewController(
            EpisodeDetailController(episode: result.episode, podcast: nil),
            animated: true
        )
    }
}
