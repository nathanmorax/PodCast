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

private enum Section: Int, CaseIterable {
    case header
    case episodes
}


class EpisodesController: UITableViewController {
    fileprivate let cellId = "cellId"
    var podcast: Podcast? {
        didSet {
            //navigationItem.title = podcast?.trackName
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
        self.setupBindings()
        
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
    fileprivate func setupTableView() {
        tableView.register(EpisodeHeaderCell.self, forCellReuseIdentifier: EpisodeHeaderCell.headerPodcastCellId)
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
        tableView.tableFooterView = UIView()
    }
    // MARK: - UITableView
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard isEpisodeSection(indexPath) else { return }
        navigateToEpisode(at: indexPath)
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        
        switch section {
        case .header:
            return 1
        case .episodes:
            return viewModel.episodes.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch section {
        case .header:
            return headerCell(tableView, at: indexPath)
            
        case .episodes:
            return episodeCell(tableView, at: indexPath)
        }
    }
    
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Section(rawValue: indexPath.section) == .header ? 250 : 180
    }
    
    
    private func headerCell(_ tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: EpisodeHeaderCell.headerPodcastCellId,
            for: indexPath
        ) as? EpisodeHeaderCell else {
            return UITableViewCell()
        }
        
        cell.configure(with: podcast)
        return cell
    }
    
    private func episodeCell(_ tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: cellId,
            for: indexPath
        ) as? EpisodeCell else {
            return UITableViewCell()
        }
        
        cell.episode = viewModel.episodes[indexPath.row]
        return cell
    }
    
    private func isEpisodeSection(_ indexPath: IndexPath) -> Bool {
        Section(rawValue: indexPath.section) == .episodes
    }
    
    private func navigateToEpisode(at indexPath: IndexPath) {
        let episode = viewModel.episodes[indexPath.row]
        
        (UIApplication.shared.keyWindow?.rootViewController as? MainTabController)?
            .maximizePlayerDetails(episode: episode)
    }
    
    
}


class EpisodeHeaderCell: UITableViewCell {
    
    static let headerPodcastCellId = "HeaderPodcastCellId"
    
    let headerImageView = UIImageView(image: UIImage(named: "appicon"))
    let titlePodcastLabel = UILabel()
    let artistNameLabel = UILabel()
    let descriptionLabel = UILabel()
    
    private let containerView = UIView()
    private var currentImageURL: String?

    
    var podcast: Podcast?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {

        selectionStyle = .none
        backgroundColor = .clear

        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true

        headerImageView.contentMode = .scaleAspectFit

        titlePodcastLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        artistNameLabel.font = .systemFont(ofSize: 14)
        artistNameLabel.textColor = .lightGray

        descriptionLabel.numberOfLines = 3
        descriptionLabel.text =
        "A string is a series of characters, such as Swift..."

        let stackView = UIStackView(arrangedSubviews: [
            headerImageView,
            titlePodcastLabel,
            artistNameLabel,
            descriptionLabel
        ])

        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(containerView)
        containerView.addSubview(stackView)

        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
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
    
    override func prepareForReuse() {
        super.prepareForReuse()

        headerImageView.image = nil
        containerView.backgroundColor = .secondarySystemBackground
        titlePodcastLabel.textColor = .label
        artistNameLabel.textColor = .secondaryLabel
        currentImageURL = nil
    }


}

