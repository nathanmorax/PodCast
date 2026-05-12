//
//  SceneDelegate.swift
//  Podcast
//
//  Created by Nathan Mora on 07/11/23.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene,
                 willConnectTo session: UISceneSession,
                 options connectionOptions: UIScene.ConnectionOptions) {
          
          guard let windowScene = (scene as? UIWindowScene) else { return }
          
          let window = UIWindow(windowScene: windowScene)
          window.rootViewController = UIHostingController(rootView: RootView())
          window.makeKeyAndVisible()
          
          self.window = window
      }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}

//
//  RootView.swift
//  Podcast
//

import SwiftUI

struct RootView: View {
    
    @State private var manager = PlayerManager.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // Tu tab bar UIKit envuelto
            MainTabBarRepresentable()
                .edgesIgnoringSafeArea(.all)
            
            // Overlay del player
            playerOverlay
        }
    }
    
    @ViewBuilder
    private var playerOverlay: some View {
        switch manager.presentation {
            
        case .hidden:
            EmptyView()
            
        case .mini:
            if let episode = manager.currentEpisode {
                MiniPlayerView(
                    episode: episode,
                    viewModel: manager.viewModel
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 60) // espacio sobre el tab bar
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onTapGesture {
                    manager.expand()
                }
            }
            
        case .expanded:
            if let episode = manager.currentEpisode {
                PlayerView(episode: episode)
                    .transition(.move(edge: .bottom))
                    .ignoresSafeArea()
                    .zIndex(1)
            }
        }
    }
}

#Preview {
    RootView()
}


//
//  MiniPlayerView.swift
//  Podcast
//

import SwiftUI

struct MiniPlayerView: View {
    
    let episode: Episode
    let viewModel: AVPlayerViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            
            PodcastImage(source: episode.imageUrl)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(.black)
                
                Text(episode.author ?? "")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            AppButton(
                style: .icon,
                tone: .brand,
                size: .compact,
                icon: .toggle(
                    selected: Image(systemName: "pause.fill"),
                    unselected: Image(systemName: "play.fill")
                ),
                title: "Play/Pause",
                isSelected: viewModel.isPlaying
            ) {
                viewModel.togglePlayPause()
            }
            
            AppButton(
                style: .icon,
                tone: .neutral,
                size: .compact,
                icon: .only(Image(systemName: "forward.fill")),
                title: "Forward"
            ) {
                viewModel.seekForward()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        )
    }
}
