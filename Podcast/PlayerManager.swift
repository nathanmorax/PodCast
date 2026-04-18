//
//  PlayerManager.swift
//  Podcast
//
//  Created by Satori Tech 341 on 23/03/26.
//
import Foundation
import UIKit

final class PlayerManager {
    static let shared = PlayerManager()
    private init() {}
    
    private weak var playerView: PlayerDetailView?
    private var topConstraint: NSLayoutConstraint?
    
    private var window: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    private var tabBarHeight: CGFloat {
        (window?.rootViewController as? UITabBarController)?.tabBar.frame.height ?? 0
    }
    
    private let miniPlayerHeight: CGFloat = 54
    
    // MARK: - Setup
    
    func setup(in window: UIWindow) {
        let playerView = PlayerDetailView.initFromNib()
        playerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.miniPlayerView.isHidden = true
        window.addSubview(playerView)
        
        let topConstraint = playerView.topAnchor.constraint(equalTo: window.bottomAnchor)
        
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            playerView.heightAnchor.constraint(equalTo: window.heightAnchor),
            topConstraint
        ])
        
        self.playerView = playerView
        self.topConstraint = topConstraint
    }
    
    // MARK: - Public API
    
    func play(episode: Episode) {
        playerView?.episode = episode
        expand()
    }
    
    func expand() {
        guard let window else { return }
        topConstraint?.constant = -window.frame.height
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut) {
            window.layoutIfNeeded()
            self.playerView?.maximizedStackView.alpha = 1
            self.playerView?.miniPlayerView.alpha = 0
            self.playerView?.backgroundColor = .black
        }
    }
    
    func collapse() {
        guard let window else { return }
        topConstraint?.constant = -(miniPlayerHeight + tabBarHeight)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut) {
            window.layoutIfNeeded()
            self.playerView?.maximizedStackView.alpha = 0
            self.playerView?.miniPlayerView.alpha = 1
            self.playerView?.miniPlayerView.isHidden = false
            self.playerView?.backgroundColor = .clear
        }
    }
}
