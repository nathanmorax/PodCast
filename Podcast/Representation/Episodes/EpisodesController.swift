//
//  EpisodesController.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import UIKit
import FeedKit
import SDWebImage
import UIImageColors

class EpisodesController: UIViewController {
    fileprivate let cellId = "cellId"
    
    private let tableView = UITableView()
    private let headerView = EpisodeHeaderView()
    private let statusBarBackgroundView = UIView()

    
    private let headerHeight: CGFloat = 320

    var podcast: Podcast? {
        didSet {
            headerView.configure(with: podcast)
            loadEpisodes()
        }
    }
    
    private lazy var viewModel: PodcastSearchViewModel = {
        let remote = PodcastRemoteDataService()
        let repository = PodcastRepositoryImpl(remoteDataSource: remote)
        return PodcastSearchViewModel(repository: repository)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTableView()
        self.setupLayout()
        self.setupBindings()
        
        edgesForExtendedLayout = [.top]
        extendedLayoutIncludesOpaqueBars = true

        
    }

    private func setupLayout() {

        view.backgroundColor = .systemBackground
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInsetAdjustmentBehavior = .never
        
        tableView.delegate = self
        tableView.dataSource = self


        view.addSubview(tableView)

        NSLayoutConstraint.activate([

            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    
    private func setupBindings() {
        
        viewModel.onDataUpdated = { [weak self] in
            self?.tableView.reloadData()
        }
        
        viewModel.onError = { error in
            print("Episodes error:", error)
        }
    }
    // MARK: - FetchEpisodes Parse RSS
    fileprivate func loadEpisodes() {
        
        guard let feedUrl =  podcast?.feedUrl else { return }
        viewModel.loadEpisodes(feedURL: feedUrl)
    }
    // MARK: - SetupWork
    
    private func setupTableView() {
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)

        let header = EpisodeHeaderView(
            frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 280)
        )

        header.configure(with: podcast)
        tableView.tableHeaderView = header
        
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let header = tableView.tableHeaderView else { return }

        let offsetY = scrollView.contentOffset.y

        if offsetY < 0 {
            header.frame = CGRect(
                x: 0,
                y: offsetY,
                width: tableView.bounds.width,
                height: headerHeight - offsetY
            )
        } else {
            // comportamiento normal
            header.frame = CGRect(
                x: 0,
                y: 0,
                width: tableView.bounds.width,
                height: headerHeight
            )
        }

        tableView.tableHeaderView = header
    }



}

extension EpisodesController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.episodes.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: cellId,
            for: indexPath
        ) as? EpisodeCell else {
            return UITableViewCell()
        }

        cell.episode = viewModel.episodes[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = viewModel.episodes[indexPath.row]

        (UIApplication.shared.keyWindow?.rootViewController as? MainTabController)?
            .maximizePlayerDetails(episode: episode)
    }
}


class EpisodeHeaderView: UIView {

    let headerImageView = UIImageView(image: UIImage(named: "appicon"))
    let titlePodcastLabel = UILabel()
    let artistNameLabel = UILabel()
    let descriptionLabel = UILabel()

    private let containerView = UIView()
    private var currentImageURL: String?

    var podcast: Podcast?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {

        backgroundColor = .clear

        containerView.translatesAutoresizingMaskIntoConstraints = false

        headerImageView.contentMode = .scaleAspectFit
        headerImageView.layer.cornerRadius = 8
        headerImageView.clipsToBounds = true

        titlePodcastLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        artistNameLabel.font = .systemFont(ofSize: 14)
        artistNameLabel.textColor = .lightGray

        descriptionLabel.numberOfLines = 3
        descriptionLabel.text = "A string is a series of characters, such as Swift..."

        let stackView = UIStackView(arrangedSubviews: [
            headerImageView,
            titlePodcastLabel,
            artistNameLabel,
            descriptionLabel
        ])

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(containerView)
        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 80),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
        ])
    }

    func configure(with podcast: Podcast?) {

        titlePodcastLabel.text = podcast?.trackName
        artistNameLabel.text = podcast?.artistName

        guard let urlString = podcast?.artworkUrl600,
              let url = URL(string: urlString) else {
            return
        }

        currentImageURL = urlString

        headerImageView.sd_setImage(with: url) { [weak self] image, _, _, _ in
            guard let self,
                  let image,
                  self.currentImageURL == urlString else { return }

            image.getColors { colors in
                guard let colors else { return }

                self.containerView.backgroundColor = colors.background
                self.titlePodcastLabel.textColor = colors.primary
                self.artistNameLabel.textColor = colors.secondary
            }
        }
    }

    func reset() {
        headerImageView.image = nil
        containerView.backgroundColor = .secondarySystemBackground
        titlePodcastLabel.textColor = .label
        artistNameLabel.textColor = .secondaryLabel
        currentImageURL = nil
    }
}

