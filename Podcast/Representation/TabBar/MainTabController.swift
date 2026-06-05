//
//  MainTabController.swift
//  Podcast
//
//  Created by Nathan Mora on 07/11/23.
//

import UIKit
import SwiftUI

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

//        self.tabBarMinimizeBehavior = .onScrollDown
        
        tabBar.tintColor = AppColor.lavender.uiColor

        self.tabs = [
            UITab(title: "Favoritos",
                  image: UIImage(systemName: "heart"),
                  identifier: "workouts") { _ in
                UINavigationController(rootViewController: DownloadEpisodeViewController())
            },
            UITab(title: "Descargas",
                  image: UIImage(systemName: "bookmark.fill"),
                  identifier: "exercises") { _ in
                UINavigationController(rootViewController: BookMarkEpisodeController())
            },
            UISearchTab { _ in
                UINavigationController(rootViewController: PodcastSearchContainerController())
            }
        ]
    }
}

struct MainTabBarRepresentable: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> MainTabBarController {
        MainTabBarController()
    }
    
    func updateUIViewController(_ uiViewController: MainTabBarController, context: Context) {
        // sin actualizaciones por ahora
    }
}
