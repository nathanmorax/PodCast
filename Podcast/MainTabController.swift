//
//  MainTabController.swift
//  Podcast
//
//  Created by Nathan Mora on 07/11/23.
//

import UIKit

class MainTabController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureTabarAppearance()
        self.setupViewControllers()
        
        
    }
    // MARK: - Setup functions

    func configureTabarAppearance() {
        UINavigationBar.appearance().prefersLargeTitles = true
        tabBar.tintColor = .purple
        
        tabBar.backgroundColor = .clear
    }
    
    func setupViewControllers() {
        viewControllers = [
            createNavigationController(
                for: PodcastSearchContainerController(),
                title: "Search",
                image: UIImage(systemName: "magnifyingglass")
            ),
            createNavigationController(
                for: FavoritesPodcastController(),
                title: "Favorites",
                image: UIImage(systemName: "heart")
            ),
            createNavigationController(
                for: UIViewController(),
                title: "Downloads",
                image: UIImage(systemName: "arrow.down.circle")
            ),
            createNavigationController(
                for: ViewController(),
                title: "Movies",
                image: UIImage(systemName: "film")
            )
        ]
    }
    
    fileprivate func createNavigationController(
        for rootViewController: UIViewController,
        title: String,
        image: UIImage?
    ) -> UIViewController {
        
        let navController = UINavigationController(rootViewController: rootViewController)
        rootViewController.navigationItem.title = title
        navController.tabBarItem.title = title
        navController.tabBarItem.image = image
        return navController
    }
}
