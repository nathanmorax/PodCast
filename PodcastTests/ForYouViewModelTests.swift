//
//  ForYouViewModelTests.swift
//  PodcastTests
//

import Testing
@testable import Podcast

@MainActor
@Suite("ForYouViewModel")
struct ForYouViewModelTests {

    private let comedy = Genre(id: "1303", name: "Comedy")
    private let science = Genre(id: "1533", name: "Science")

    @Test("One mixed row, searching each genre's name")
    func mix() async {
        let repository = MockSearchPodcastRepository(podcasts: [Fixtures.podcast(id: 1), Fixtures.podcast(id: 2)])
        let sut = ForYouViewModel(repository: repository)

        sut.load(genres: [comedy, science], excluding: [])
        await sut.loadTask?.value

        // Both genres returned the same two: no repeats.
        #expect(sut.podcasts.map(\.trackId) == [1, 2])
        #expect(Set(await repository.searchedQueries) == ["Comedy", "Science"])
        #expect(!sut.isLoading)
    }

    @Test("Podcasts you follow are left out")
    func excludesFollowing() async {
        let repository = MockSearchPodcastRepository(podcasts: [Fixtures.podcast(id: 1), Fixtures.podcast(id: 2)])
        let sut = ForYouViewModel(repository: repository)

        sut.load(genres: [comedy], excluding: [1])
        await sut.loadTask?.value

        #expect(sut.podcasts.map(\.trackId) == [2])
    }

    @Test("Cached genres don't search again")
    func cache() async {
        let repository = MockSearchPodcastRepository(podcasts: [Fixtures.podcast(id: 1)])
        let sut = ForYouViewModel(repository: repository)

        sut.load(genres: [comedy], excluding: [])
        await sut.loadTask?.value
        sut.load(genres: [comedy], excluding: [])
        await sut.loadTask?.value

        #expect(await repository.searchedQueries == ["Comedy"])
        #expect(sut.podcasts.count == 1)
    }

    @Test("A failed search just adds nothing")
    func failure() async {
        let repository = MockSearchPodcastRepository(error: TestError())
        let sut = ForYouViewModel(repository: repository)

        sut.load(genres: [comedy], excluding: [])
        await sut.loadTask?.value

        #expect(sut.podcasts.isEmpty)
        #expect(!sut.isLoading)
    }

    @Test("At most four genres are searched")
    func maxGenres() async {
        let repository = MockSearchPodcastRepository(podcasts: [Fixtures.podcast(id: 1)])
        let sut = ForYouViewModel(repository: repository)

        sut.load(genres: Array(Genre.podcastCatalog.prefix(6)), excluding: [])
        await sut.loadTask?.value

        #expect(await repository.searchedQueries.count == ForYouViewModel.maxGenres)
    }

    @Test("Interleave takes one of each genre in turn, without repeats, up to the limit")
    func interleave() {
        let a = [1, 2, 3].map { Fixtures.podcast(id: $0) }
        let b = [10, 2, 20].map { Fixtures.podcast(id: $0) }

        let mixed = ForYouViewModel.interleave([a, b], excluding: [3], limit: 4)

        #expect(mixed.map(\.trackId) == [1, 10, 2, 20])
    }
}
