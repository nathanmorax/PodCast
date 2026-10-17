//
//  NewEpisodesViewModelTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

@MainActor
@Suite("NewEpisodesViewModel")
struct NewEpisodesViewModelTests {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func podcast(_ id: Int, feed: String? = "https://example.com/feed") -> Podcast {
        Podcast(trackId: id, trackName: "P\(id)", artistName: nil, artworkUrl600: nil,
                primaryGenreName: nil, trackCount: nil, feedUrl: feed)
    }

    private func episode(_ url: String, daysAgo: Double) -> Episode {
        Episode(title: url, author: "A", pubDate: now.addingTimeInterval(-daysAgo * 86_400),
                description: "", streamUrl: url)
    }

    @Test("Only recent, unstarted episodes, newest first")
    func pick() {
        let latest: [Int: Episode] = [
            1: episode("old", daysAgo: 10),
            2: episode("new", daysAgo: 1),
            3: episode("newest", daysAgo: 0.5),
            4: episode("played", daysAgo: 0.2),
        ]

        let items = NewEpisodesViewModel.pick(
            following: [podcast(1), podcast(2), podcast(3), podcast(4)],
            latest: latest, played: ["played"], now: now
        )

        #expect(items.map(\.episode.streamUrl) == ["newest", "new"])
    }

    @Test("Reads each followed feed once and keeps its newest episode")
    func loadsNewest() async {
        let repository = MockSearchPodcastRepository(episodes: [
            episode("a", daysAgo: 3), episode("b", daysAgo: 1),
        ])
        let sut = NewEpisodesViewModel(repository: repository)

        sut.load(following: [podcast(1)], played: [], now: now)
        await sut.loadTask?.value
        sut.load(following: [podcast(1)], played: [], now: now)
        await sut.loadTask?.value

        #expect(sut.items.map(\.episode.streamUrl) == ["b"])
        #expect(await repository.fetchedFeeds.count == 1)
        #expect(!sut.isLoading)
    }

    @Test("Podcasts without a feed, or failed feeds, are skipped")
    func skips() async {
        let repository = MockSearchPodcastRepository(error: TestError())
        let sut = NewEpisodesViewModel(repository: repository)

        sut.load(following: [podcast(1), podcast(2, feed: nil)], played: [], now: now)
        await sut.loadTask?.value

        #expect(sut.items.isEmpty)
        #expect(await repository.fetchedFeeds.count == 1)
    }
}
