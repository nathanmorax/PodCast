//
//  FollowingFeedViewModelTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

@MainActor
@Suite("FollowingFeedViewModel")
struct FollowingFeedViewModelTests {

    private func episode(_ name: String, at seconds: TimeInterval) -> Episode {
        Episode(title: name, author: "A", pubDate: Date(timeIntervalSince1970: seconds),
                description: "", streamUrl: "https://example.com/\(name).mp3")
    }

    @Test("Reads each followed feed once")
    func feedCache() async {
        let repository = MockSearchPodcastRepository(episodes: [episode("x", at: 1)])
        let sut = FollowingFeedViewModel(repository: repository)

        sut.load(following: [Fixtures.podcast(id: 1)])
        await sut.loadTask?.value
        sut.load(following: [Fixtures.podcast(id: 1)])
        await sut.loadTask?.value

        #expect(sut.episodesByPodcast[1]?.map(\.title) == ["x"])
        #expect(await repository.fetchedFeeds == ["https://example.com/feed/1"])
        #expect(!sut.isLoading)
    }

    @Test("Unfollowing removes its episodes right away")
    func unfollow() async {
        let repository = MockSearchPodcastRepository(episodes: [episode("x", at: 1)])
        let sut = FollowingFeedViewModel(repository: repository)

        sut.load(following: [Fixtures.podcast(id: 1)])
        await sut.loadTask?.value
        sut.load(following: [])

        #expect(sut.episodesByPodcast.isEmpty)
    }

    @Test("A failed feed just adds nothing")
    func failure() async {
        let sut = FollowingFeedViewModel(repository: MockSearchPodcastRepository(error: TestError()))

        sut.load(following: [Fixtures.podcast(id: 1)])
        await sut.loadTask?.value

        #expect(sut.episodesByPodcast.isEmpty)
        #expect(!sut.isLoading)
    }

    @Test("After closing the app, the saved episodes are there at once and then refresh")
    func savedEpisodesShowAtOnce() async {
        let cache = FollowingFeedCache(userDefaults: .isolated())
        let podcast = Fixtures.podcast(id: 1)

        let first = FollowingFeedViewModel(repository: MockSearchPodcastRepository(episodes: [episode("old", at: 1)]), cache: cache)
        first.load(following: [podcast])
        await first.loadTask?.value

        let repository = MockSearchPodcastRepository(episodes: [episode("new", at: 2)])
        let second = FollowingFeedViewModel(repository: repository, cache: cache)
        second.load(following: [podcast])
        #expect(second.episodesByPodcast[1]?.map(\.title) == ["old"])

        await second.loadTask?.value
        #expect(second.episodesByPodcast[1]?.map(\.title) == ["new"])
        #expect(await repository.fetchedFeeds.count == 1)
    }

    @Test("The saved copy keeps the newest few, without the long notes")
    func cacheIsLight() {
        let cache = FollowingFeedCache(userDefaults: .isolated(), perPodcast: 2)
        var withNotes = episode("a", at: 3)
        withNotes.showNotes = String(repeating: "x", count: 10_000)
        cache.save([1: [episode("b", at: 1), withNotes, episode("c", at: 2)]])

        let saved = cache.load()[1] ?? []
        #expect(saved.map(\.title) == ["a", "c"])
        #expect(saved.allSatisfy { $0.showNotes == nil })
    }
}
