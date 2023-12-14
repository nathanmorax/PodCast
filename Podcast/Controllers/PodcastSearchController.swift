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
   var podcasts = [Podcast]()
   
   let searchController = UISearchController(searchResultsController: nil)
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      setupSearchBar()
      setupTableView()
      searchBar(searchController.searchBar, textDidChange: "pension")
      
   }
   fileprivate func setupSearchBar() {
      self.definesPresentationContext = true
      navigationItem.searchController = searchController
      navigationItem.hidesSearchBarWhenScrolling = false
      searchController.obscuresBackgroundDuringPresentation = false
      searchController.searchBar.delegate = self
   }
   
   func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
      
      APIService.shared.fetchPodcast(searchText: searchText) { (podcast) in
         self.podcasts = podcast
         self.tableView.reloadData()
      }
   }
   
   fileprivate func setupTableView() {
      //tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
      let nib = UINib(nibName: "PodcastCell", bundle: nil)
      tableView.register(nib, forCellReuseIdentifier: cellId)

   }
   
   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return podcasts.count
   }
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! PodcastCell
      let podcast = podcasts[indexPath.row]
      
      cell.podcast = podcast
      
      /*cell.textLabel?.text = "\(data.trackName ?? "")\n\(data.artistName ?? "")"
      cell.textLabel?.numberOfLines = -1*/
      return cell
   }
   
   override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      let episodesController = EpisodesController()
      let podcast = self.podcasts[indexPath.row]
      episodesController.podcast = podcast
      print("name:", podcast.feedUrl)
      navigationController?.pushViewController(episodesController, animated: true)
   }
   
   override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 140
   }
}
