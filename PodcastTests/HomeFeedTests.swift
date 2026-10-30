//
//  HomeFeedTests.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

@Suite("HomeFeed")
struct HomeFeedTests {

    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func item(_ url: String, show: Int = 1, hoursAgo: Double = 1, minutes: Double = 40) -> PodcastEpisode {
        PodcastEpisode(
            podcast: Fixtures.podcast(id: show),
            episode: Episode(title: url, author: "", pubDate: now.addingTimeInterval(-hoursAgo * 3600),
                             description: "", durationSeconds: minutes * 60, streamUrl: url)
        )
    }

    private func played(_ url: String, at seconds: TimeInterval, progress: Double) -> RecentlyPlayed {
        RecentlyPlayed(
            episode: Episode(title: url, author: "", pubDate: now, description: "", streamUrl: url),
            lastPlayedAt: Date(timeIntervalSince1970: seconds),
            progress: progress
        )
    }

    @Test("The first pick is the episode of the day, the next one's show is spotlighted")
    func order() {
        let feed = HomeFeed.build(
            newEpisodes: [item("n1"), item("n2"), item("n3"), item("n4")],
            newSince: now.addingTimeInterval(-2 * 3600),
            picks: [item("p1", show: 7), item("p2", show: 8), item("p3", show: 9)],
            unfinished: [played("c1", at: 5, progress: 0.4)]
        )
        #expect(feed.map(\.id) == [
            "day-p1", "episode-n1", "continue-c1", "episode-n2", "episode-n3",
            "show-8", "episode-n4", "episode-p3"
        ])
    }

    @Test("With no picks, the newest episode leads")
    func noPicks() {
        let feed = HomeFeed.build(newEpisodes: [item("n1"), item("n2")], newSince: now, picks: [], unfinished: [])
        #expect(feed.map(\.id) == ["day-n1", "episode-n2"])
    }

    @Test("Nothing shows twice")
    func noRepeats() {
        let shared = item("same")
        let feed = HomeFeed.build(newEpisodes: [shared], newSince: now, picks: [shared], unfinished: [])
        #expect(feed.map(\.id) == ["day-same"])
    }

    @Test("Tags: new, then short, then for you")
    func tags() {
        let since = now.addingTimeInterval(-2 * 3600)
        #expect(HomeFeed.tag(for: item("a", hoursAgo: 1), isPick: false, newSince: since) == .new)
        #expect(HomeFeed.tag(for: item("b", hoursAgo: 5, minutes: 12), isPick: false, newSince: since) == .shortListen)
        #expect(HomeFeed.tag(for: item("c", hoursAgo: 5), isPick: true, newSince: since) == .forYou)
        #expect(HomeFeed.tag(for: item("d", hoursAgo: 5), isPick: false, newSince: since) == nil)
    }

    @Test("Continue listening: only unfinished ones, last played first")
    func unfinishedOnly() {
        let items = [
            played("done", at: 30, progress: 0.99),
            played("half", at: 10, progress: 0.5),
            played("started", at: 20, progress: 0.1)
        ]
        #expect(HomeFeed.unfinished(items).map(\.id) == ["started", "half"])
    }
}
