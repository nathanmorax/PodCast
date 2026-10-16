//
//  MainTabController.swift
//  Podcast
//
//  Created by Nathan Mora on 07/11/23.
//

import UIKit
import SwiftUI

class MainTabBarController: UITabBarController {

    private let playerManager: PlayerManager

    init(playerManager: PlayerManager = .shared) {
        self.playerManager = playerManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The mini player as the tab bar's bottom accessory (iOS 26).
    /// Before, it floated in a SwiftUI ZStack over this controller with a hard-coded
    /// `.padding(.bottom, 60)`: UIKit didn't know it existed, so Search results and
    /// lists scrolled underneath it. As an accessory, the system places it right
    /// above the tab bar, draws the glass and reserves its space.
    private lazy var miniPlayerAccessory: UITabAccessory = {
        let hosting = UIHostingController(
            rootView: MiniPlayerAccessory()
                .environment(\.playerManager, playerManager)
        )
        hosting.view.backgroundColor = .clear
        addChild(hosting)
        hosting.didMove(toParent: self)
        return UITabAccessory(contentView: hosting.view)
    }()

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
        
        observePlayer()
    }

    // MARK: - Mini player

    /// Shows the accessory while there is an episode, hides it otherwise.
    private func observePlayer() {
        withObservationTracking {
            updateMiniPlayer(animated: viewIfLoaded?.window != nil)
        } onChange: { [weak self] in
            // onChange fires before the new value is stored: read it on the next turn.
            Task { @MainActor in
                self?.observePlayer()
            }
        }
    }

    private func updateMiniPlayer(animated: Bool) {
        let shouldShow = playerManager.currentEpisode != nil
        let isShowing = bottomAccessory != nil
        guard shouldShow != isShowing else { return }
        setBottomAccessory(shouldShow ? miniPlayerAccessory : nil, animated: animated)
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
