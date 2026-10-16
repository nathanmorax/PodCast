//
//  GenrePodcastsController.swift
//  Podcast
//

import UIKit

/// The podcasts of one category, pushed from Search: the category's name
/// centered in a normal navigation bar, with the back arrow.
///
/// For now it searches the category's name; when the API gives us each
/// category's top podcasts, only `load()` changes.
final class GenrePodcastsController: UIViewController {

    private let genre: Genre

    private lazy var viewModel: PodcastSearchViewModel = {
        let remote = PodcastRemoteDataService()
        let repository = PodcastRepositoryImpl(remoteDataSource: remote)
        return PodcastSearchViewModel(repository: repository)
    }()

    private lazy var resultsController = PodcastResultSearchController(viewModel: viewModel)

    init(genre: Genre) {
        self.genre = genre
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = genre.name
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = AppColor.screenBackground.uiColor
        embedResults()
        load()
    }

    private func load() {
        viewModel.search(genre.name)
    }

    private func embedResults() {
        addChild(resultsController)
        view.addSubview(resultsController.view)
        resultsController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resultsController.view.topAnchor.constraint(equalTo: view.topAnchor),
            resultsController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            resultsController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            resultsController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        resultsController.didMove(toParent: self)
    }
}
