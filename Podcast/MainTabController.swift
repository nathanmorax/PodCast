//
//  MainTabController.swift
//  Podcast
//
//  Created by Nathan Mora on 07/11/23.
//

import UIKit

private enum PlayerState {
    case minimized, maximized
}

class MainTabController: UITabBarController {
    let playerDetailView = PlayerDetailView.initFromNib()
    var maximizedTopAnchorConstraint: NSLayoutConstraint!
    var minimizedTopAnchorConstraint: NSLayoutConstraint!
    
    var heightConstraint: NSLayoutConstraint!
    var bottomAnchorConstraint: NSLayoutConstraint!
    private let miniPlayerHeight: CGFloat = 54
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UINavigationBar.appearance().prefersLargeTitles = true
        tabBar.tintColor = .purple
        
        tabBar.backgroundColor = .clear
        
        setupViewControllers()
        setupPlayerDetailsView()
        
        playerDetailView.miniPlayerView.isHidden = true
        
    }
    // MARK: - Setup functions
    
    @objc func minimizePlayerDetails() {
        maximizedTopAnchorConstraint.isActive = false
        bottomAnchorConstraint.isActive = false
        heightConstraint.isActive = true
        minimizedTopAnchorConstraint.isActive = true
        additionalSafeAreaInsets.bottom = miniPlayerHeight
        animatePlayer(to: .minimized)
        
        
    }
    
    func maximizePlayerDetails(episode: Episode?) {
        if playerDetailView.transform != .identity {
            heightConstraint.isActive = true
            minimizedTopAnchorConstraint.isActive = true
            playerDetailView.transform = .identity
            view.layoutIfNeeded()
        }
        
        minimizedTopAnchorConstraint.isActive = false
        heightConstraint.isActive = false
        maximizedTopAnchorConstraint.isActive = true
        bottomAnchorConstraint.isActive = true
        
        if let episode { playerDetailView.episode = episode }
        
        additionalSafeAreaInsets.bottom = 0
        animatePlayer(to: .maximized)
    }
    
    private func animatePlayer(to state: PlayerState) {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 1,
            options: .curveEaseOut
        ) {
            self.view.layoutIfNeeded()
            
            switch state {
            case .minimized:
                self.playerDetailView.maximizedStackView.alpha = 0
                self.playerDetailView.miniPlayerView.alpha = 1
                self.playerDetailView.miniPlayerView.isHidden = false
                self.playerDetailView.backgroundColor = .clear
            case .maximized:
                self.playerDetailView.maximizedStackView.alpha = 1
                self.playerDetailView.miniPlayerView.alpha = 0
                self.playerDetailView.backgroundColor = .black
                self.tabBar.frame.origin.y = self.view.frame.height
            }
        }
    }
    
    func setupPlayerDetailsView() {
        print("Setting up PlayerDetailsView")
        
        view.insertSubview(playerDetailView, belowSubview: tabBar)
        
        playerDetailView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playerDetailView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerDetailView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        heightConstraint = playerDetailView.heightAnchor.constraint(equalToConstant: miniPlayerHeight)
        
        bottomAnchorConstraint = playerDetailView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        maximizedTopAnchorConstraint = playerDetailView.topAnchor.constraint(equalTo: view.topAnchor)
        
        minimizedTopAnchorConstraint = playerDetailView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -miniPlayerHeight - 55)
        
        playerDetailView.transform = CGAffineTransform(translationX: 0, y: view.frame.height)
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
