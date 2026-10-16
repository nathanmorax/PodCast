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
    
    private var navigator: AppNavigator { .shared }
    
    /// Bar height + the gap under it + breathing room above it.
    /// Uses the resting size even while the bar is folded, so lists don't jump
    /// as you scroll. While typing, the bar is just the search field.
    private var reservedBottomSpace: CGFloat {
        let bar = navigator.isSearching
            ? BottomBar.Metrics.rowHeight
            : BottomBar.restingHeight(isPlaying: manager.currentEpisode != nil)
        return bar + 8 + 12
    }
    
    /// Hidden only while the full player is open.
    private var showsBottomBar: Bool {
        manager.presentation != .expanded
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            MainNavigationRepresentable(bottomInset: showsBottomBar ? reservedBottomSpace : 0)
                .ignoresSafeArea(.container)
            
            if showsBottomBar {
                BottomBar(navigator: navigator)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    // Respects the keyboard: while typing, the search field
                    // sits right above it.
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            playerOverlay
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showsBottomBar)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: navigator.isSearching)
    }
    
    @ViewBuilder
    private var playerOverlay: some View {
        if manager.presentation == .expanded, let episode = manager.currentEpisode {
            PlayerView(episode: episode)
                .transition(.move(edge: .bottom))
                .ignoresSafeArea()
                .zIndex(1)
                .environment(\.episodeActions, headerActions)
        }
    }
}

#Preview {
    RootView()
        .environment(\.playerManager, .preview)
}
