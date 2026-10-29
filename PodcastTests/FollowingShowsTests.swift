//
//  FollowingShowsTests.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

@Suite("FollowingShows")
struct FollowingShowsTests {

    private func podcast(_ id: Int) -> Podcast {
        Podcast(trackId: id, trackName: "\(id)", artistName: nil, artworkUrl600: nil,
                primaryGenreName: nil, trackCount: nil, feedUrl: nil)
    }

    private func episode(_ url: String, at seconds: TimeInterval) -> Episode {
        Episode(title: url, author: "A", pubDate: Date(timeIntervalSince1970: seconds),
                description: "", streamUrl: url)
    }

    @Test("Shows with new episodes first, then the newest latest")
    func order() {
        let rows = FollowingShows.rows(
            podcasts: [podcast(1), podcast(2), podcast(3), podcast(4)],
            episodes: [1: [episode("a", at: 30)], 2: [episode("b", at: 10)], 3: [episode("c", at: 20)]],
            newEpisodes: [2: [episode("b", at: 10)]]
        )
        #expect(rows.map(\.id) == [2, 1, 3, 4])
        #expect(rows.first?.newCount == 1)
    }

    @Test("The latest is the newest episode")
    func latest() {
        let rows = FollowingShows.rows(
            podcasts: [podcast(1)],
            episodes: [1: [episode("old", at: 1), episode("new", at: 5)]],
            newEpisodes: [:]
        )
        #expect(rows.first?.latest?.streamUrl == "new")
    }

    @Test("Shows without episodes keep the order they were followed")
    func stable() {
        let rows = FollowingShows.rows(podcasts: [podcast(5), podcast(6)], episodes: [:], newEpisodes: [:])
        #expect(rows.map(\.id) == [5, 6])
    }

    @Test("Today and yesterday by name")
    func whenLabel() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(FollowingShows.whenLabel(now, now: now) == String(localized: "Today"))
        #expect(FollowingShows.whenLabel(now.addingTimeInterval(-86_400), now: now) == String(localized: "Yesterday"))
    }
}
