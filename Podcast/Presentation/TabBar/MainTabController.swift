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
        
        tabBar.tintColor = AppColor.lavender.uiColor

        self.tabs = [
//            UITab(title: "Descargas",
//                  image: UIImage(systemName: "arrow.down.circle"),
//                  identifier: "workouts") { _ in
//                UINavigationController(rootViewController: DownloadEpisodeViewController())
//            },
//            UITab(title: "Guardados",
//                  image: UIImage(systemName: "bookmark.fill"),
//                  identifier: "exercises") { _ in
//                UINavigationController(rootViewController: BookMarkEpisodeController())
//            },
            UITab(title: "Biblioteca",
                  image: UIImage(systemName: "square.stack"),
                  identifier: "biblioteca") { _ in
                UINavigationController(rootViewController: LibraryController())
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
