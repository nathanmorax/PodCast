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

    @Test("Tabs: the mini player sits next to the search circle")
    func tabs() {
        #expect(layout(playing: true).player == .inline)
        #expect(layout(playing: false).player == .none)
        #expect(layout(playing: true).showsSearchRow)
    }

    @Test("Search: the mini player gets its own row above the field")
    func search() {
        let bar = layout(playing: true, inSearch: true)
        #expect(bar.player == .above)
        #expect(bar.showsSearchRow)
        #expect(bar.height(row: 62, playerRow: 56, spacing: 10) == 128)
    }

    @Test("Search while typing: only the field, the keyboard needs the room")
    func searchTyping() {
        let bar = layout(playing: true, inSearch: true, typing: true)
        #expect(bar.player == .none)
        #expect(bar.height(row: 62, playerRow: 56, spacing: 10) == 62)
    }

    @Test("Podcast opened from Search: the mini player is the whole bar")
    func searchDetailPlaying() {
        let bar = layout(playing: true, inSearch: true, detail: true)
        #expect(bar.player == .alone)
        #expect(!bar.showsSearchRow)
        #expect(bar.isVisible)
        #expect(bar.height(row: 62, playerRow: 56, spacing: 10) == 62)
    }

    @Test("Podcast opened from Search with nothing playing: no bar")
    func searchDetailIdle() {
        let bar = layout(playing: false, inSearch: true, detail: true)
        #expect(!bar.isVisible)
        #expect(bar.height(row: 62, playerRow: 56, spacing: 10) == 0)
    }
}
