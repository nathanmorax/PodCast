//
//  EpisodesController.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import UIKit
import FeedKit

class EpisodesController: UITableViewController {
    fileprivate let cellId = "cellId"
    var podcast: Podcast? {
        didSet {
            navigationItem.title = podcast?.trackName
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
        //tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        let nib = UINib(nibName: "EpisodeCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
        tableView.tableFooterView = UIView()
    }
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episode = self.viewModel.episodes[indexPath.row]
        let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabController
        mainTabBarController?.maximizePlayerDetails(episode: episode)
        /*let window = UIApplication.shared.keyWindow
         
         let playerDetailView = PlayerDetailView.initFromNib()
         playerDetailView.frame = self.view.frame
         playerDetailView.episode = episode
         window?.addSubview(playerDetailView)
         print("Autor: ", episode.author)*/
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.episodes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
        let episode = viewModel.episodes[indexPath.row]
        cell.episode = episode
        /*cell.textLabel?.numberOfLines = 0
         cell.textLabel?.text = episode.title + "\n" + episode.pubDate.description*/
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180
    }
    
}
