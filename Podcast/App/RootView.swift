//
//  RootView.swift
//  Podcast
//
//  Created by Jonathan Mora on 12/05/26.
//


import SwiftUI

struct RootView: View {
    
    @Environment(\.playerManager) private var manager
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
            
        case .hidden, .mini:
            // The mini player lives in the tab bar's bottom accessory
            // (MainTabBarController), so nothing is overlaid here.
            EmptyView()
            
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
        .environment(\.playerManager, .preview)
}


