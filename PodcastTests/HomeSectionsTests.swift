//
//  HomeSectionsTests.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

@Suite("HomeSections")
struct HomeSectionsTests {

    private func item(_ url: String, show: Int = 1) -> PodcastEpisode {
        PodcastEpisode(
            podcast: Fixtures.podcast(id: show),
            episode: Episode(title: url, author: "", pubDate: .now, description: "", streamUrl: url)
        )
    }

    @Test("Latest stops at its limit, newest first as given")
    func latest() {
        let latest = HomeSections.latest((1...20).map { item("e\($0)") })
        #expect(latest.count == HomeSections.latestLimit)
        #expect(latest.first?.id == "e1")
    }

    @Test("For You skips what's already in Latest")
    func picks() {
        let picks = HomeSections.picks([item("a", show: 2), item("b", show: 3)], excluding: [item("a")])
        #expect(picks.map(\.id) == ["b"])
    }
}

@Suite("HomeSections · Recently played")
struct HomeRecentlyPlayedTests {

    private func played(_ url: String, at seconds: TimeInterval) -> RecentlyPlayed {
        RecentlyPlayed(
            episode: Episode(title: url, author: "", pubDate: .now, description: "", streamUrl: url),
            lastPlayedAt: Date(timeIntervalSince1970: seconds),
            progress: 0.5
        )
    }

    @Test("The latest played first, up to the limit")
    func order() {
        let items = (1...12).map { played("e\($0)", at: TimeInterval($0)) }
        let recent = HomeSections.recentlyPlayed(items)
        #expect(recent.count == HomeSections.recentLimit)
        #expect(recent.first?.id == "e12")
    }
}
