//
//  AppNavigator.swift
//  Podcast
//

import UIKit
import Observation

/// App-level navigation state shared between UIKit (the navigation stacks)
/// and SwiftUI (the bottom bar in RootView).
@MainActor
@Observable
final class AppNavigator {

    static let shared = AppNavigator()

    /// True while the search field has the keyboard: the bar shows only the
    /// field (above the keyboard) and a cancel button.
    var isSearching = false

    /// What's typed in the bar's search field. PodcastSearchContainerController
    /// observes it and shows results or categories.
    var searchQuery = ""

    /// The last tab chosen in the bar. Stays set while Search is on screen, so
    /// the bar knows where you came from.
    private(set) var selectedTab: AppTab = .home

    /// Search is on screen. It has its own navigation stack (Search is the
    /// root, so there's no back arrow); choosing a tab leaves it.
    private(set) var isShowingSearch = false

    /// True on screens opened from Search (a category, a podcast): no bottom
    /// bar there. Set by MainContainerController as screens are shown.
    var hidesBottomBar = false
    /// The podcast page shows no bottom bar at all (not even the mini player).
    var hidesBarCompletely = false

    @ObservationIgnored
    weak var container: (any NavigationContainer)?

    /// The stack on screen: Search's or the selected tab's.
    var currentNavigationController: UINavigationController? {
        isShowingSearch ? container?.searchStack : container?.stack(for: selectedTab)
    }

    /// Tapping the tab you're already in goes back to its first screen.
    func select(_ tab: AppTab) {
        if !isShowingSearch, tab == selectedTab {
            if let stack = currentNavigationController {
                // Animate only what's on screen; off screen the pop happens
                // right away (an animated pop off screen is deferred).
                stack.popToRootViewController(animated: stack.viewIfLoaded?.window != nil)
            }
            return
        }
        isShowingSearch = false
        selectedTab = tab
        container?.show(tab)
    }

    // MARK: - Search field

    /// Leaves Search (it drops back down) to the tab you came from.
    func closeSearch() {
        guard isShowingSearch else { return }
        isSearching = false
        select(selectedTab)
    }

    /// The ✕ next to the field while typing: clears it and drops the keyboard.
    func cancelSearchEditing() {
        searchQuery = ""
        isSearching = false
    }

    /// Shows Search without the keyboard (tap the bar's field to type). If
    /// Search is already on screen, goes back to its first screen and focuses
    /// the field.
    func showSearch() {
        guard let container else { return }
        if isShowingSearch {
            container.focusSearch()
            return
        }
        isShowingSearch = true
        container.showSearch()
    }
}
