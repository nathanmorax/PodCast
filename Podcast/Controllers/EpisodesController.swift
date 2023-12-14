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
   var episodes = [Episode]()
   var podcast: Podcast? {
      didSet {
         navigationItem.title = podcast?.trackName
         fetchEpisodes()
         
      }
   }
   
   override func viewDidLoad() {
      super.viewDidLoad()
      self.setupTableView()
      
   }
   // MARK: - FetchEpisodes Parse RSS
   fileprivate func fetchEpisodes() {
      print("Looking for episodes at feed url:", podcast?.feedUrl ?? "")
      
      guard let feedUrl = podcast?.feedUrl else { return }
      
      APIService.shared.fetchEpisodes(feedUrl: feedUrl) { (episodes) in
         self.episodes = episodes
         DispatchQueue.main.async {
            self.tableView.reloadData()
         }
      }
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
      let episode = self.episodes[indexPath.row]
      let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabController
      mainTabBarController?.maximizePlayerDetail(episode: episode)
      /*let window = UIApplication.shared.keyWindow
      
      let playerDetailView = PlayerDetailView.initFromNib()
      playerDetailView.frame = self.view.frame
      playerDetailView.episode = episode
      window?.addSubview(playerDetailView)
      print("Autor: ", episode.author)*/
      
   }
   
   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return episodes.count
   }
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! EpisodeCell
      let episode = episodes[indexPath.row]
      cell.episode = episode
      /*cell.textLabel?.numberOfLines = 0
       cell.textLabel?.text = episode.title + "\n" + episode.pubDate.description*/
      return cell
   }
   
   override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      return 180
   }
   
}
