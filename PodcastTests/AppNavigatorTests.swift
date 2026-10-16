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

    @Test("Starts on Inicio, outside Search")
    func initialState() {
        #expect(sut.selectedTab == .home)
        #expect(!sut.isShowingSearch)
        #expect(sut.currentNavigationController === container.stacks[.home])
    }

    @Test("Choosing another tab shows its stack")
    func selectOtherTab() {
        sut.select(.library)

        #expect(sut.selectedTab == .library)
        #expect(container.shownTabs == [.library])
        #expect(sut.currentNavigationController === container.stacks[.library])
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

    @Test("Choosing a tab or search unfolds the bar")
    func navigationUnfoldsBar() {
        sut.isBarCompact = true
        sut.select(.library)
        #expect(!sut.isBarCompact)

        sut.isBarCompact = true
        sut.showSearch()
        #expect(!sut.isBarCompact)

        sut.isBarCompact = true
        sut.expandBar()
        #expect(!sut.isBarCompact)
    }

    // MARK: - Swipe between tabs

    @Test("Swiping left on Inicio goes to Biblioteca")
    func swipeToNext() {
        let moved = sut.swipeTab(towardNext: true)

        #expect(moved)
        #expect(sut.selectedTab == .library)
        #expect(container.shownTabs == [.library])
    }

    @Test("Swiping right on Biblioteca goes back to Inicio")
    func swipeToPrevious() {
        sut.select(.library)

        sut.swipeTab(towardNext: false)

        #expect(sut.selectedTab == .home)
        #expect(container.shownTabs == [.library, .home])
    }

    @Test("At either end the swipe does nothing", arguments: [(AppTab.home, false), (AppTab.library, true)])
    func swipePastTheEnd(start: AppTab, towardNext: Bool) {
        if start != sut.selectedTab { sut.select(start) }
        let shownBefore = container.shownTabs

        let moved = sut.swipeTab(towardNext: towardNext)

        #expect(!moved)
        #expect(sut.selectedTab == start)
        #expect(container.shownTabs == shownBefore)
    }

    @Test("From Search, a swipe lands on the tab at that end")
    func swipeFromSearch() {
        sut.showSearch()
        #expect(sut.tab(forSwipeTowardNext: true) == .library)
        #expect(sut.tab(forSwipeTowardNext: false) == .home)

        sut.swipeTab(towardNext: true)

        #expect(!sut.isShowingSearch)
        #expect(sut.selectedTab == .library)
    }

    @Test("Neighbors follow the bar's order", arguments: [
        (AppTab.home, true, AppTab?.some(.library)),
        (AppTab.home, false, nil),
        (AppTab.library, true, nil),
        (AppTab.library, false, AppTab?.some(.home)),
    ])
    func neighbors(tab: AppTab, towardNext: Bool, expected: AppTab?) {
        #expect(tab.neighbor(towardNext: towardNext) == expected)
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
}
