//
//  EpisodeListTests.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

@Suite("EpisodeList")
struct EpisodeListTests {

    private func episode(_ url: String, at seconds: TimeInterval) -> Episode {
        Episode(title: url, author: "", pubDate: Date(timeIntervalSince1970: seconds),
                description: "", streamUrl: url)
    }

    private var feed: [Episode] {
        [episode("b", at: 20), episode("a", at: 10), episode("c", at: 30)]
    }

    @Test("Newest first, or oldest first")
    func order() {
        let newest = EpisodeList.apply(feed, filter: .all, order: .newest, finished: [], downloaded: [])
        let oldest = EpisodeList.apply(feed, filter: .all, order: .oldest, finished: [], downloaded: [])
        #expect(newest.map(\.streamUrl) == ["c", "b", "a"])
        #expect(oldest.map(\.streamUrl) == ["a", "b", "c"])
    }

    @Test("Unplayed leaves out the finished ones")
    func unplayed() {
        let list = EpisodeList.apply(feed, filter: .unplayed, order: .newest, finished: ["c"], downloaded: [])
        #expect(list.map(\.streamUrl) == ["b", "a"])
    }

    @Test("Downloaded keeps only what's on the phone")
    func downloaded() {
        let list = EpisodeList.apply(feed, filter: .downloaded, order: .newest, finished: [], downloaded: ["a"])
        #expect(list.map(\.streamUrl) == ["a"])
    }

    @Test("Same date: the feed's order stays")
    func stable() {
        let same = [episode("1", at: 0), episode("2", at: 0), episode("3", at: 0)]
        let list = EpisodeList.apply(same, filter: .all, order: .newest, finished: [], downloaded: [])
        #expect(list.map(\.streamUrl) == ["1", "2", "3"])
    }
}
