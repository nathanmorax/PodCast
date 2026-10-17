//
//  AppNavigatorTests.swift
//  PodcastTests
//

import Testing
import UIKit
@testable import Podcast

@MainActor
struct AppNavigatorTests {

    private let container = FakeNavigationContainer()
    private let sut: AppNavigator

    init() {
        sut = AppNavigator()
        sut.container = container
    }

    @Test("Starts on Library, outside Search")
    func initialState() {
        #expect(sut.selectedTab == .home)
        #expect(!sut.isShowingSearch)
        #expect(sut.currentNavigationController === container.stacks[.home])
    }

    @Test("Choosing the tab you're in goes back to its first screen")
    func reselectPopsToRoot() throws {
        let home = try #require(container.stacks[.home])
        home.pushViewController(UIViewController(), animated: false)

        sut.select(.home)

        #expect(home.viewControllers.count == 1)
        #expect(container.shownTabs.isEmpty)
    }

    @Test("Search opens its own stack, so it has no back arrow")
    func showSearch() {
        sut.showSearch()

        #expect(sut.isShowingSearch)
        #expect(container.showSearchCount == 1)
        #expect(sut.currentNavigationController === container.searchStack)
        #expect(container.searchStack.viewControllers.count == 1)
    }

    @Test("Tapping search again while in Search only focuses the field")
    func showSearchTwiceFocuses() {
        sut.showSearch()

        sut.showSearch()

        #expect(container.showSearchCount == 1)
        #expect(container.focusSearchCount == 1)
    }

    @Test("Choosing a tab leaves Search, even the tab you came from", arguments: AppTab.allCases)
    func selectLeavesSearch(tab: AppTab) {
        sut.showSearch()

        sut.select(tab)

        #expect(!sut.isShowingSearch)
        #expect(sut.selectedTab == tab)
        #expect(container.shownTabs == [tab])
        #expect(sut.currentNavigationController === container.stacks[tab])
    }

    // MARK: - Search field

    @Test("The ✕ next to the field clears it and drops the keyboard")
    func cancelSearchEditing() {
        sut.showSearch()
        sut.isSearching = true
        sut.searchQuery = "radio"

        sut.cancelSearchEditing()

        #expect(sut.searchQuery.isEmpty)
        #expect(!sut.isSearching)
        #expect(sut.isShowingSearch)
    }

    // MARK: - Closing Search

    @Test("Closing Search goes back to the tab you came from and drops the keyboard")
    func closeSearch() {
        sut.showSearch()
        sut.isSearching = true

        sut.closeSearch()

        #expect(!sut.isShowingSearch)
        #expect(!sut.isSearching)
        #expect(sut.selectedTab == .home)
        #expect(container.shownTabs == [.home])
        #expect(sut.currentNavigationController === container.stacks[.home])
    }

    @Test("Closing Search when it isn't open does nothing")
    func closeSearchOutsideSearch() {
        sut.closeSearch()

        #expect(container.shownTabs.isEmpty)
        #expect(sut.selectedTab == .home)
    }
}
