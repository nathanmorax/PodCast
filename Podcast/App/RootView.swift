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
    private static let reservedBottomSpace: CGFloat = BottomBar.height + 8 + 12
    
    /// Hidden while typing in Search and while the full player is open.
    private var showsBottomBar: Bool {
        !navigator.isSearching && manager.presentation != .expanded
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            MainNavigationRepresentable(bottomInset: showsBottomBar ? Self.reservedBottomSpace : 0)
                .ignoresSafeArea(.container)
            
            if showsBottomBar {
                BottomBar(onSearch: { navigator.showSearch() })
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .ignoresSafeArea(.keyboard)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            playerOverlay
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showsBottomBar)
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
