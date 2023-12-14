//
//  MainTabController.swift
//  Podcast
//
//  Created by Nathan Mora on 07/11/23.
//

import UIKit

class MainTabController: UITabBarController {
   let playerDetailView = PlayerDetailView.initFromNib()
   var maximizedTopAnchorConstraint: NSLayoutConstraint!
   var minimizedTopAnchorConstraint: NSLayoutConstraint!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      UINavigationBar.appearance().prefersLargeTitles = true
      
      tabBar.tintColor = .purple
      
      setupViewControllers()
      setupDetailView()
     
   }
   // MARK: - Setup functions
   
   @objc func minimizePlayerDetail() {
      maximizedTopAnchorConstraint.isActive = false
      minimizedTopAnchorConstraint.isActive = true
      UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut) {
         self.view.layoutIfNeeded()
         self.tabBar.transform = .identity

      }
   }
   func maximizePlayerDetail(episode: Episode?) {
      maximizedTopAnchorConstraint.isActive = true
      maximizedTopAnchorConstraint.constant = 0
      minimizedTopAnchorConstraint.isActive = false
      
      if episode != nil {
          playerDetailView.episode = episode
      }
      
      UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
          
          self.view.layoutIfNeeded()
          
          self.tabBar.transform = CGAffineTransform(translationX: 0, y: 100)
          
      })
   }

   fileprivate func setupDetailView() {
      
      // use auto layout
//        view.addSubview(playerDetailsView)
      view.insertSubview(playerDetailView, belowSubview: tabBar)
      
      // enables auto layout
      playerDetailView.translatesAutoresizingMaskIntoConstraints = false
      
      maximizedTopAnchorConstraint = playerDetailView.topAnchor.constraint(equalTo: view.topAnchor, constant: view.frame.height)
      
      maximizedTopAnchorConstraint.isActive = true
      
      minimizedTopAnchorConstraint = playerDetailView.topAnchor.constraint(equalTo: tabBar.topAnchor, constant: -64)
//        minimizedTopAnchorConstraint.isActive = true
      
      playerDetailView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
      playerDetailView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
      playerDetailView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
      
      
   }
   
   func setupViewControllers() {
      viewControllers = [
         createNavigationController(for: PodcastSearchController(), title: "Search", image: #imageLiteral(resourceName: "search")),
         createNavigationController(for: ViewController(), title: "Favorites", image: #imageLiteral(resourceName: "favorites")),
         createNavigationController(for: ViewController(), title: "Downloads", image: #imageLiteral(resourceName: "downloads"))
      ]
   }
   
   fileprivate func createNavigationController(for rootViewController: UIViewController, title: String, image: UIImage) -> UIViewController {
      
      let navController = UINavigationController(rootViewController: rootViewController)
      rootViewController.navigationItem.title = title
      navController.tabBarItem.title = title
      navController.tabBarItem.image = image
      return navController
   }
}
