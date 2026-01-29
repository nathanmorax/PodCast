//
//  PodcastSearchController.swift
//  Podcast
//
//  Created by Nathan Mora on 08/11/23.
//

import UIKit
import Alamofire

class PodcastSearchController: UITableViewController, UISearchBarDelegate {
    let cellId = "cellId"
    let searchController = UISearchController(searchResultsController: nil)
    
    private lazy var viewModel: PodcastSearchViewModel = {
        let remote = PodcastRemoteDataService()
        let repository = PodcastRepositoryImpl(remoteDataSource: remote)
        return PodcastSearchViewModel(repository: repository)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSearchBar()
        setupTableView()
        setupBindings()
        searchBar(searchController.searchBar, textDidChange: "")
        
    }
    
    private func setupBindings() {
        
        viewModel.onDataUpdated = { [weak self] in
            self?.tableView.reloadData()
        }
        
        viewModel.onError = { error in
            print(error)
        }
        
    }
    
    fileprivate func setupSearchBar() {
        self.definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        viewModel.seacrhPodcast(searchPodcast: searchText)
    }
    
    fileprivate func setupTableView() {
        let nib = UINib(nibName: "PodcastCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellId)
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.podcasts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! PodcastCell
        let podcast = viewModel.podcasts[indexPath.row]
        
        cell.podcast = podcast
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let episodesController = EpisodesController()
        let podcast = self.viewModel.podcasts[indexPath.row]
        episodesController.podcast = podcast
        print("name:", podcast.feedUrl)
        navigationController?.pushViewController(episodesController, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
}
