//
//  RootView.swift
//  Podcast
//
//  Created by Jonathan Mora on 12/05/26.
//


import SwiftUI

struct RootView: View {
    
    @Environment(\.playerManager) private var manager
    @Environment(\.interestsManager) private var interests
    let headerActions = EpisodeHeaderActions()
    
    private var navigator: AppNavigator { .shared }
    
    /// Bar height + the gap under it + breathing room above it.
    /// Uses the resting size even while the bar is folded, so lists don't jump
    /// as you scroll. While typing, the bar is just the search field.
    private var barLayout: BottomBarLayout {
        BottomBar.layout(navigator: navigator, isPlaying: manager.currentEpisode != nil)
    }

    private var reservedBottomSpace: CGFloat {
        BottomBar.restingHeight(barLayout) + 8 + 12
    }
    
    /// Hidden while the full player is open, and on screens opened from
    /// Search when nothing is playing (there the bar is just the mini player).
    private var showsBottomBar: Bool {
        manager.presentation != .expanded && hasBar
    }

    /// The current screen has a bar (the podcast page has none).
    private var hasBar: Bool {
        barLayout.isVisible && !navigator.hidesBarCompletely
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // The inset doesn't depend on the full player: opening/closing it
            // must not resize the list behind it (that showed up as a jump
            // peeking out while the player slid down).
            MainNavigationRepresentable(bottomInset: hasBar ? reservedBottomSpace : 0)
                .ignoresSafeArea(.container)
            
            // The bar's animations live on its own container. On the ZStack
            // they also overrode the player's own close animation (both change
            // in the same frame), so the player left with the bar's timing.
            ZStack(alignment: .bottom) {
                if showsBottomBar {
                    BottomBar(navigator: navigator)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        // Respects the keyboard: while typing, the search field
                        // sits right above it.
                        .transition(.bottomBar)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .animation(AppAnimation.barVisibility, value: showsBottomBar)
            .animation(AppAnimation.barVisibility, value: navigator.isSearching)
            
            playerOverlay

            // First launch (and "Edit" in Home): what do you like to listen to?
            if interests.needsOnboarding {
                OnboardingView(selectedIDs: interests.genreIDs)
                    .transition(.onboarding)
                    .zIndex(2)
            }
        }
        .animation(AppAnimation.onboarding, value: interests.needsOnboarding)
    }
    
    @ViewBuilder
    private var playerOverlay: some View {
        if manager.presentation == .expanded, let episode = manager.currentEpisode {
            PlayerView(episode: episode)
                .transition(.playerSheet)
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
