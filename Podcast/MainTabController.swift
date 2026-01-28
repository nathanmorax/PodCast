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
    
    var heightConstraint: NSLayoutConstraint!
    var bottomAnchorConstraint: NSLayoutConstraint!
    private let miniPlayerHeight: CGFloat = 54

    
    override func viewDidLoad() {
        super.viewDidLoad()
        UINavigationBar.appearance().prefersLargeTitles = true
        
        tabBar.tintColor = .purple
        
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
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            
            self.playerDetailView.maximizedStackView.alpha = 0
            self.playerDetailView.miniPlayerView.alpha = 1
            self.playerDetailView.miniPlayerView.isHidden = false
            self.playerDetailView.backgroundColor = .clear
        })
    }
    
    func maximizePlayerDetails(episode: Episode?) {
        // Si está oculto, mostrarlo primero
        let isHidden = playerDetailView.transform != .identity
        
        if isHidden {
            // Activar constraints de mini player
            heightConstraint.isActive = true
            minimizedTopAnchorConstraint.isActive = true
            playerDetailView.transform = .identity
            view.layoutIfNeeded()
        }
        
        // Ahora maximizar
        minimizedTopAnchorConstraint.isActive = false
        heightConstraint.isActive = false
        
        maximizedTopAnchorConstraint.isActive = true
        bottomAnchorConstraint.isActive = true
        
        if episode != nil {
            playerDetailView.episode = episode
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            
            self.playerDetailView.maximizedStackView.alpha = 1
            self.playerDetailView.miniPlayerView.alpha = 0
            self.playerDetailView.backgroundColor = .black
        })
    }
    
    fileprivate func setupPlayerDetailsView() {
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
        
        minimizedTopAnchorConstraint = playerDetailView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -miniPlayerHeight - 35)
        
        playerDetailView.transform = CGAffineTransform(translationX: 0, y: view.frame.height)
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

//https://github.com/nmdias/FeedKit.git 10.3.0
//https://github.com/SDWebImage/SDWebImage 5.21.5
//https://github.com/Alamofire/Alamofire 5.11.0

