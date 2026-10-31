//
//  NewEpisodeMarksTests.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

@Suite("NewEpisodeMarks")
struct NewEpisodeMarksTests {

    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func episode(_ url: String, hoursAgo: Double) -> Episode {
        Episode(title: url, author: "", pubDate: now.addingTimeInterval(-hoursAgo * 3600),
                description: "", streamUrl: url)
    }

    @Test("New = after the Inbox's last visit, newest first")
    func afterInbox() {
        let episodes = [Podcast.mock.trackId: [
            episode("old", hoursAgo: 48),
            episode("a", hoursAgo: 5),
            episode("b", hoursAgo: 1)
        ]]
        let marks = NewEpisodeMarks.newEpisodes(
            podcasts: [.mock], episodes: episodes,
            inboxSeen: now.addingTimeInterval(-24 * 3600), showSeen: [:], now: now
        )
        #expect(marks[Podcast.mock.trackId]?.map(\.streamUrl) == ["b", "a"])
    }

    @Test("Opening the show's page later hides what came before")
    func showSeenWins() {
        let episodes = [Podcast.mock.trackId: [episode("a", hoursAgo: 5), episode("b", hoursAgo: 1)]]
        let marks = NewEpisodeMarks.newEpisodes(
            podcasts: [.mock], episodes: episodes,
            inboxSeen: now.addingTimeInterval(-24 * 3600),
            showSeen: [Podcast.mock.trackId: now.addingTimeInterval(-2 * 3600)],
            now: now
        )
        #expect(marks[Podcast.mock.trackId]?.map(\.streamUrl) == ["b"])
    }

    @Test("Shows with nothing new are left out")
    func nothingNew() {
        let episodes = [Podcast.mock.trackId: [episode("old", hoursAgo: 48)]]
        let marks = NewEpisodeMarks.newEpisodes(
            podcasts: [.mock], episodes: episodes,
            inboxSeen: now.addingTimeInterval(-24 * 3600), showSeen: [:], now: now
        )
        #expect(marks.isEmpty)
    }
}

@Suite("NewEpisodeMarks · order")
struct NewEpisodeMarksOrderTests {

    private func episode(_ url: String, at seconds: TimeInterval) -> Episode {
        Episode(title: url, author: "", pubDate: Date(timeIntervalSince1970: seconds),
                description: "", streamUrl: url)
    }

    @Test("Shows with new episodes first, the newest leading; the rest as they were")
    func newFirst() {
        let podcasts = (1...4).map { Fixtures.podcast(id: $0) }
        let order = NewEpisodeMarks.newFirst(podcasts, newEpisodes: [
            3: [episode("c", at: 10)],
            4: [episode("d", at: 20)]
        ])
        #expect(order.map(\.trackId) == [4, 3, 1, 2])
    }
}
