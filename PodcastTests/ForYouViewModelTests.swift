//
//  ForYouViewModelTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

/// "For you" is discovery: podcasts you don't follow, from your interests.
@MainActor
@Suite("ForYouViewModel")
struct ForYouViewModelTests {

    private func episode(_ name: String, at seconds: TimeInterval) -> Episode {
        Episode(title: name, author: "A", pubDate: Date(timeIntervalSince1970: seconds),
                description: "", streamUrl: "https://example.com/\(name).mp3")
    }

    private func ids(_ podcasts: [Podcast]) -> [Int] { podcasts.map(\.trackId) }

    @Test("Categories take turns, skipping what you follow and repeats")
    func pick() {
        let p = (1...6).map { Fixtures.podcast(id: $0) }
        let picked = ForYouViewModel.pick(
            from: [[p[0], p[1], p[2]], [p[1], p[3], p[4]]],
            excluding: [p[0].trackId],
            perGenre: 2
        )
        // Category 1: 2, 3 (1 is followed). Category 2: 4, 5 (2 already taken).
        #expect(ids(picked) == [2, 4, 3, 5])
    }

    @Test("Shows without a feed are skipped")
    func pickNeedsFeed() {
        let noFeed = Podcast(trackId: 9, trackName: "X", artistName: nil, artworkUrl600: nil,
                             primaryGenreName: nil, trackCount: nil, feedUrl: nil)
        let picked = ForYouViewModel.pick(from: [[noFeed, Fixtures.podcast(id: 2)]], excluding: [], perGenre: 1)
        #expect(ids(picked) == [2])
    }

    @Test("Loads the newest episode of shows you don't follow")
    func load() async {
        let repository = MockSearchPodcastRepository(
            podcasts: [Fixtures.podcast(id: 1), Fixtures.podcast(id: 2)],
            episodes: [episode("old", at: 1), episode("new", at: 2)]
        )
        let sut = ForYouViewModel(repository: repository)

        sut.load(interests: [Genre(id: "1489", name: "News")], following: [Fixtures.podcast(id: 1)])
        await sut.loadTask?.value

        #expect(sut.items.map(\.podcast.trackId) == [2])
        #expect(sut.items.map(\.episode.title) == ["new"])
        #expect(await repository.searchedQueries == ["News"])
        #expect(!sut.isLoading)
    }

    @Test("Following one of them takes it out right away, without reloading")
    func followHides() async {
        let repository = MockSearchPodcastRepository(
            podcasts: [Fixtures.podcast(id: 2)], episodes: [episode("e", at: 1)]
        )
        let sut = ForYouViewModel(repository: repository)
        sut.load(interests: [Genre(id: "1489", name: "News")], following: [])
        await sut.loadTask?.value

        #expect(sut.visibleItems(excluding: [2]).isEmpty)
        sut.load(interests: [Genre(id: "1489", name: "News")], following: [Fixtures.podcast(id: 2)])
        #expect(await repository.searchedQueries.count == 1)
    }

    @Test("After closing the app, the last row is there at once and refreshes in place")
    func savedRowShowsAtOnce() async {
        let cache = ForYouCache(userDefaults: .isolated())
        let news = [Genre(id: "1489", name: "News")]

        let first = ForYouViewModel(
            repository: MockSearchPodcastRepository(podcasts: [Fixtures.podcast(id: 2)], episodes: [episode("old", at: 1)]),
            cache: cache
        )
        first.load(interests: news, following: [])
        await first.loadTask?.value

        // Next launch: the saved row before anything is fetched…
        let second = ForYouViewModel(
            repository: MockSearchPodcastRepository(podcasts: [Fixtures.podcast(id: 2)], episodes: [episode("new", at: 2)]),
            cache: cache
        )
        #expect(second.items.map(\.episode.title) == ["old"])

        // …kept while the fresh one loads, then replaced in place.
        second.load(interests: news, following: [])
        #expect(second.items.map(\.episode.title) == ["old"])
        await second.loadTask?.value
        #expect(second.items.map(\.episode.title) == ["new"])
    }

    @Test("A row saved for other interests isn't shown")
    func savedRowForOtherInterests() async {
        let cache = ForYouCache(userDefaults: .isolated())
        cache.save([PodcastEpisode(podcast: Fixtures.podcast(id: 2), episode: episode("old", at: 1))], key: "1303")

        let sut = ForYouViewModel(repository: MockSearchPodcastRepository(), cache: cache)
        sut.load(interests: [Genre(id: "1489", name: "News")], following: [])

        #expect(sut.items.isEmpty)
    }
}
