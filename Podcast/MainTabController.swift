//
//  MainTabController.swift
//  Podcast
//
//  Created by Nathan Mora on 07/11/23.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBarMinimizeBehavior = .onScrollDown
        
        tabBar.tintColor = AppColor.lavender.uiColor

        self.tabs = [
            UITab(title: "Favoritos",
                  image: UIImage(systemName: "heart"),
                  identifier: "workouts") { _ in
                UINavigationController(rootViewController: FavoritesPodcastController())
            },
            UITab(title: "Descargas",
                  image: UIImage(systemName: "square.and.arrow.down.fill"),
                  identifier: "exercises") { _ in
                UINavigationController(rootViewController: PodcastSearchContainerController())
            },
            UISearchTab { _ in
                UINavigationController(rootViewController: PodcastSearchContainerController())
            }
        ]
    }
}
