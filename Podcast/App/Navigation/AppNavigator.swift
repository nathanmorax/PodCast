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

    /// Scrolling down folds the bar into one row; scrolling up (or reaching the
    /// top) brings it back. Driven by BottomBarScrollTracker.
    var isBarCompact = false

    @ObservationIgnored
    weak var container: (any NavigationContainer)?

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

    // MARK: - Swipe between tabs

    /// The tab a horizontal swipe on the bar lands on: the one beside the
    /// current tab, or nil at either end. From Search, the tab at that end.
    func tab(forSwipeTowardNext next: Bool) -> AppTab? {
        if isShowingSearch {
            return next ? AppTab.allCases.last : AppTab.allCases.first
        }
        return selectedTab.neighbor(towardNext: next)
    }

    /// Finger to the left → the tab on the right (like Safari's tab bar).
    /// Returns false at the ends, where the bar only bounces.
    @discardableResult
    func swipeTab(towardNext next: Bool) -> Bool {
        guard let tab = tab(forSwipeTowardNext: next) else { return false }
        select(tab)
        return true
    }

    /// Tapping the tab pill: the other tab. From Search, back to the tab you
    /// came from.
    func showOtherTab() {
        if isShowingSearch {
            select(selectedTab)
            return
        }
        let hasNext = selectedTab.neighbor(towardNext: true) != nil
        swipeTab(towardNext: hasNext)
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

    /// Shows Search with the keyboard up. If Search is already on screen,
    /// goes back to its first screen and focuses the field.
    func showSearch() {
        isBarCompact = false
        guard let container else { return }
        if isShowingSearch {
            container.focusSearch()
            return
        }
        isShowingSearch = true
        container.showSearch()
    }
}
