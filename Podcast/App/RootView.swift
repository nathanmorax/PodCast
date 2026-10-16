//
//  RootView.swift
//  Podcast
//
//  Created by Jonathan Mora on 12/05/26.
//


import SwiftUI

struct RootView: View {
    
    @State private var manager = PlayerManager.shared
    let headerActions = EpisodeHeaderActions()

    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            MainTabBarRepresentable()
                // Same as the old edgesIgnoringSafeArea(.all): container only.
                // UIKit handles the keyboard itself inside the tab controller.
                .ignoresSafeArea(.container)
            
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
                    viewModel: manager.viewModel,
                    onExpand: { manager.expand() }
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 60)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
        case .expanded:
            if let episode = manager.currentEpisode {
                PlayerView(episode: episode)
                    .transition(.move(edge: .bottom))
                    .ignoresSafeArea()
                    .zIndex(1)
                    .environment(\.episodeActions, headerActions)
            }
        }
    }
}

#Preview {
    RootView()
}


