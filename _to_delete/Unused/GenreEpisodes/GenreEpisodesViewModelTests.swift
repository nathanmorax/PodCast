//
//  GenreEpisodesViewModelTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

@MainActor
@Suite("GenreEpisodesViewModel")
struct GenreEpisodesViewModelTests {

    private let comedy = Genre(id: "1303", name: "Comedy")

    private func episode(_ name: String, at seconds: TimeInterval) -> Episode {
        Episode(title: name, author: "A", pubDate: Date(timeIntervalSince1970: seconds),
                description: "", streamUrl: "https://example.com/\(name).mp3")
    }

    @Test("Each top podcast gives its newest episode, in the podcasts' order")
    func rank() {
        let a = Fixtures.podcast(id: 1), b = Fixtures.podcast(id: 2), c = Fixtures.podcast(id: 3)
        let items = GenreEpisodesViewModel.rank([a, b, c], newest: [3: episode("c", at: 9), 1: episode("a", at: 1)])
        #expect(items.map(\.episode.title) == ["a", "c"])
    }

    @Test("Loads a genre once and keeps it")
    func loadsOnce() async {
        let repository = MockSearchPodcastRepository(
            podcasts: [Fixtures.podcast(id: 1)],
            episodes: [episode("old", at: 1), episode("new", at: 2)]
        )
        let sut = GenreEpisodesViewModel(repository: repository)

        await sut.load(comedy)
        await sut.load(comedy)

        #expect(sut.items(for: comedy).map(\.episode.title) == ["new"])
        #expect(await repository.searchedQueries == ["Comedy"])
        #expect(!sut.isLoading(comedy))
    }

    @Test("A failed search marks the genre as failed")
    func failure() async {
        let sut = GenreEpisodesViewModel(repository: MockSearchPodcastRepository(error: TestError()))

        await sut.load(comedy)

        #expect(sut.hasFailed(comedy))
        #expect(sut.items(for: comedy).isEmpty)
    }
}
