//
//  GenreCoversViewModelTests.swift
//  PodcastTests
//

import Testing
@testable import Podcast

@MainActor
@Suite("GenreCoversViewModel")
struct GenreCoversViewModelTests {

    private let comedy = Genre(id: "1303", name: "Comedy")

    private func podcast(_ id: Int, artwork: String?) -> Podcast {
        Podcast(trackId: id, trackName: "P\(id)", artistName: nil, artworkUrl600: artwork,
                primaryGenreName: nil, trackCount: nil, feedUrl: nil)
    }

    @Test("Keeps the first two covers of the category's search")
    func topTwo() async {
        let repository = MockSearchPodcastRepository(podcasts: [
            podcast(1, artwork: "a"), podcast(2, artwork: nil), podcast(3, artwork: "c"), podcast(4, artwork: "d")
        ])
        let sut = GenreCoversViewModel(repository: repository)

        await sut.load(comedy)

        #expect(sut.coverURLs(for: comedy) == ["a", "c"])
        #expect(await repository.searchedQueries == ["Comedy"])
    }

    @Test("A loaded category doesn't search again")
    func cached() async {
        let repository = MockSearchPodcastRepository(podcasts: [podcast(1, artwork: "a")])
        let sut = GenreCoversViewModel(repository: repository)

        await sut.load(comedy)
        await sut.load(comedy)

        #expect(await repository.searchedQueries.count == 1)
    }

    @Test("A failed search leaves the placeholders and can retry")
    func failure() async {
        let sut = GenreCoversViewModel(repository: MockSearchPodcastRepository(error: TestError()))
        await sut.load(comedy)
        #expect(sut.coverURLs(for: comedy).isEmpty)
        #expect(sut.covers[comedy.id] == nil)
    }
}
