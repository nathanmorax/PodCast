//
//  LibraryGroupsTests.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

@Suite("LibraryGroups")
struct LibraryGroupsTests {

    private func item(_ url: String, show: String) -> LibraryItem {
        LibraryItem(episode: Episode(title: url, author: show, pubDate: .now, description: "", streamUrl: url))
    }

    @Test("Shows keep the order of their first episode")
    func showOrder() {
        let groups = LibraryGroups.group([
            item("a1", show: "A"), item("b1", show: "B"), item("a2", show: "A"), item("c1", show: "C")
        ])
        #expect(groups.map(\.showName) == ["A", "B", "C"])
    }

    @Test("Each show keeps its episodes in order")
    func episodeOrder() {
        let groups = LibraryGroups.group([
            item("a1", show: "A"), item("b1", show: "B"), item("a2", show: "A")
        ])
        #expect(groups.first?.items.map(\.id) == ["a1", "a2"])
    }

    @Test("Nothing in, nothing out")
    func empty() {
        #expect(LibraryGroups.group([]).isEmpty)
    }

    @Test("Layouts: the list has no columns, the grids two and three")
    func layoutColumns() {
        #expect(LibraryLayout.list.columns == nil)
        #expect(LibraryLayout.twoColumns.columns == 2)
        #expect(LibraryLayout.threeColumns.columns == 3)
    }
}
