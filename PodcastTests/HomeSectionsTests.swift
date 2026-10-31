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
