//
//  RootView.swift
//  Podcast
//
//  Created by Satori Tech 341 on 12/05/26.
//


import SwiftUI

struct RootView: View {
    
    @State private var manager = PlayerManager.shared
    let headerActions = EpisodeHeaderActions()

    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            MainTabBarRepresentable()
                .edgesIgnoringSafeArea(.all)
            
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
                .padding(.bottom, 60)
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
                    .environment(\.episodeActions, headerActions)
            }
        }
    }
}

#Preview {
    RootView()
}


