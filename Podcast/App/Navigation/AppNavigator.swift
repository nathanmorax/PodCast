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

    /// True while the search field has the keyboard: the bottom bar steps aside.
    var isSearching = false

    /// The last tab chosen in the bar. Stays set while Search is on screen, so
    /// the bar knows where you came from.
    private(set) var selectedTab: AppTab = .home

    /// Search is on screen. It has its own navigation stack (Search is the
    /// root, so there's no back arrow); choosing a tab leaves it.
    private(set) var isShowingSearch = false

    /// Scrolling down folds the bar into one row; scrolling up (or reaching the
    /// top) brings it back. Driven by BottomBarScrollTracker.
    var isBarCompact = false

    @ObservationIgnored
    weak var container: MainContainerController?

    /// The stack on screen: Search's or the selected tab's.
    var currentNavigationController: UINavigationController? {
        isShowingSearch ? container?.searchStack : container?.stack(for: selectedTab)
    }

    /// Tapping the tab you're already in goes back to its first screen.
    func select(_ tab: AppTab) {
        isBarCompact = false
        if !isShowingSearch, tab == selectedTab {
            currentNavigationController?.popToRootViewController(animated: true)
            return
        }
        isShowingSearch = false
        selectedTab = tab
        container?.show(tab)
    }

    func expandBar() {
        isBarCompact = false
    }

    /// Shows Search with the keyboard up. If Search is already on screen,
    /// goes back to its first screen and focuses the field.
    func showSearch() {
        isBarCompact = false
        guard let container else { return }
        if isShowingSearch {
            if container.searchStack.topViewController === container.searchController {
                container.searchController.focusSearchField()
            } else {
                // Inside a podcast opened from the results: go back first; the
                // keyboard comes up once Search is visible again.
                container.searchController.focusesSearchOnAppear = true
                container.searchStack.popToRootViewController(animated: true)
            }
            return
        }
        isShowingSearch = true
        container.showSearch()
    }
}
