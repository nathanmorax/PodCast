//
//  BottomBarLayoutTests.swift
//  PodcastTests
//

import Testing
@testable import Podcast

@Suite("BottomBarLayout")
struct BottomBarLayoutTests {

    private func layout(playing: Bool, inSearch: Bool = false, typing: Bool = false, detail: Bool = false) -> BottomBarLayout {
        BottomBarLayout(isPlaying: playing, inSearch: inSearch, isTyping: typing, isSearchDetail: detail)
    }

    @Test("Library: the mini player sits next to the search circle")
    func tabs() {
        #expect(layout(playing: true).player == .inline)
        #expect(layout(playing: false).player == .none)
        #expect(layout(playing: true).showsSearchRow)
    }

    @Test("Search: never the mini player, just the field")
    func search() {
        let bar = layout(playing: true, inSearch: true)
        #expect(bar.player == .none)
        #expect(bar.showsSearchRow)
        #expect(bar.height(row: 62) == 62)
        #expect(layout(playing: true, inSearch: true, typing: true).player == .none)
    }

    @Test("Screens opened from Search: no bar, playing or not")
    func searchDetail() {
        #expect(!layout(playing: true, inSearch: true, detail: true).isVisible)
        #expect(!layout(playing: false, inSearch: true, detail: true).isVisible)
        #expect(layout(playing: true, inSearch: true, detail: true).height(row: 62) == 0)
    }

    @Test("A podcast's page: only the mini player while playing, from any stack")
    func podcastPage() {
        let fromLibrary = BottomBarLayout(isPlaying: true, inSearch: false, isTyping: false, isSearchDetail: false, isPodcastPage: true)
        #expect(fromLibrary.player == .inline)
        #expect(!fromLibrary.showsSearchRow)
        #expect(fromLibrary.height(row: 62) == 62)

        let fromSearch = BottomBarLayout(isPlaying: true, inSearch: true, isTyping: false, isSearchDetail: true, isPodcastPage: true)
        #expect(fromSearch.player == .inline)
        #expect(!fromSearch.showsSearchRow)

        let idle = BottomBarLayout(isPlaying: false, inSearch: false, isTyping: false, isSearchDetail: false, isPodcastPage: true)
        #expect(!idle.isVisible)
    }
}
