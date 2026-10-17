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

    @Test("One row per genre, searching each genre's name")
    func rows() async {
        let repository = MockSearchPodcastRepository(podcasts: [Fixtures.podcast(id: 1), Fixtures.podcast(id: 2)])
        let sut = ForYouViewModel(repository: repository)

        sut.load(genres: [comedy, science], excluding: [])
        await sut.loadTask?.value

        #expect(sut.rows.map(\.id) == ["1303", "1533"])
        #expect(Set(await repository.searchedQueries) == ["Comedy", "Science"])
        #expect(!sut.isLoading)
    }

    @Test("Favorites are left out")
    func excludesFavorites() async {
        let repository = MockSearchPodcastRepository(podcasts: [Fixtures.podcast(id: 1), Fixtures.podcast(id: 2)])
        let sut = ForYouViewModel(repository: repository)

        sut.load(genres: [comedy], excluding: [1])
        await sut.loadTask?.value

        #expect(sut.rows.first?.podcasts.map(\.trackId) == [2])
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
        #expect(sut.rows.count == 1)
    }

    @Test("A failed search just has no row")
    func failure() async {
        let repository = MockSearchPodcastRepository(error: TestError())
        let sut = ForYouViewModel(repository: repository)

        sut.load(genres: [comedy], excluding: [])
        await sut.loadTask?.value

        #expect(sut.rows.isEmpty)
        #expect(!sut.isLoading)
    }

    @Test("At most four rows")
    func maxRows() async {
        let repository = MockSearchPodcastRepository(podcasts: [Fixtures.podcast(id: 1)])
        let sut = ForYouViewModel(repository: repository)

        sut.load(genres: Array(Genre.podcastCatalog.prefix(6)), excluding: [])
        await sut.loadTask?.value

        #expect(sut.rows.count == ForYouViewModel.maxRows)
    }
}
