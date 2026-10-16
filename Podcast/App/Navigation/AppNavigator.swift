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

    private(set) var selectedTab: AppTab = .home

    /// Scrolling down folds the bar into one row; scrolling up (or reaching the
    /// top) brings it back. Driven by BottomBarScrollTracker.
    var isBarCompact = false

    @ObservationIgnored
    weak var container: MainContainerController?

    /// The stack of the tab on screen.
    var currentNavigationController: UINavigationController? {
        container?.stack(for: selectedTab)
    }

    /// Tapping the tab you're already in goes back to its first screen.
    func select(_ tab: AppTab) {
        isBarCompact = false
        guard tab != selectedTab else {
            currentNavigationController?.popToRootViewController(animated: true)
            return
        }
        selectedTab = tab
        container?.show(tab)
    }

    func expandBar() {
        isBarCompact = false
    }

    /// Opens Search on top of the current tab (or just focuses the field if
    /// it's already the visible screen).
    func showSearch() {
        guard let navigationController = currentNavigationController else { return }
        isBarCompact = false
        if let search = navigationController.topViewController as? PodcastSearchContainerController {
            search.focusSearchField()
            return
        }
        let search = PodcastSearchContainerController()
        search.focusesSearchOnAppear = true
        navigationController.pushViewController(search, animated: true)
    }
}
