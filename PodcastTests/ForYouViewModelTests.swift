//
//  ForYouViewModelTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

@MainActor
@Suite("ForYouViewModel")
struct ForYouViewModelTests {

    private func episode(_ name: String, at seconds: TimeInterval) -> Episode {
        Episode(title: name, author: "A", pubDate: Date(timeIntervalSince1970: seconds),
                description: "", streamUrl: "https://example.com/\(name).mp3")
    }

    @Test("Newest episodes of what you follow, newest first, two per podcast")
    func latest() {
        let a = Fixtures.podcast(id: 1), b = Fixtures.podcast(id: 2)
        let items = ForYouViewModel.latest(from: [a, b], episodes: [
            1: [episode("a1", at: 100), episode("a2", at: 300), episode("a3", at: 500)],
            2: [episode("b1", at: 400)],
        ])

        #expect(items.map(\.episode.title) == ["a3", "b1", "a2"])
    }

    @Test("Never more than shownCount")
    func limit() {
        let podcasts = (1...20).map { Fixtures.podcast(id: $0) }
        let episodes = Dictionary(uniqueKeysWithValues: podcasts.map {
            ($0.trackId, [episode("e\($0.trackId)", at: TimeInterval($0.trackId))])
        })

        #expect(ForYouViewModel.latest(from: podcasts, episodes: episodes).count == ForYouViewModel.shownCount)
    }

    @Test("Reads each followed feed once")
    func feedCache() async {
        let repository = MockSearchPodcastRepository(episodes: [episode("x", at: 1)])
        let sut = ForYouViewModel(repository: repository)

        sut.load(following: [Fixtures.podcast(id: 1)])
        await sut.loadTask?.value
        sut.load(following: [Fixtures.podcast(id: 1)])
        await sut.loadTask?.value

        #expect(sut.items.map(\.episode.title) == ["x"])
        #expect(await repository.fetchedFeeds == ["https://example.com/feed/1"])
        #expect(!sut.isLoading)
    }

    @Test("Unfollowing removes its episodes right away")
    func unfollow() async {
        let repository = MockSearchPodcastRepository(episodes: [episode("x", at: 1)])
        let sut = ForYouViewModel(repository: repository)

        sut.load(following: [Fixtures.podcast(id: 1)])
        await sut.loadTask?.value
        sut.load(following: [])

        #expect(sut.items.isEmpty)
    }

    @Test("A failed feed just adds nothing")
    func failure() async {
        let repository = MockSearchPodcastRepository(error: TestError())
        let sut = ForYouViewModel(repository: repository)

        sut.load(following: [Fixtures.podcast(id: 1)])
        await sut.loadTask?.value

        #expect(sut.items.isEmpty)
        #expect(!sut.isLoading)
    }
}
