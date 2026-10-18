//
//  GenreRankingViewModelTests.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

@MainActor
@Suite("GenreRankingViewModel")
struct GenreRankingViewModelTests {

    private let science = Genre(id: "1533", name: "Science")

    @Test("Loads the category by searching its name")
    func loadsByName() async {
        let repository = MockSearchPodcastRepository(podcasts: [Fixtures.podcast(id: 1), Fixtures.podcast(id: 2)])
        let sut = GenreRankingViewModel(genre: science, repository: repository)

        sut.load()
        await sut.loadTask?.value

        #expect(sut.podcasts.map(\.trackId) == [1, 2])
        #expect(await repository.searchedQueries == ["Science"])
        #expect(sut.isLoading == false)
    }

    @Test("A failure shows an error and can be retried")
    func failure() async {
        let repository = MockSearchPodcastRepository(error: TestError())
        let sut = GenreRankingViewModel(genre: science, repository: repository)

        sut.load()
        await sut.loadTask?.value
        #expect(sut.error != nil)

        sut.load()
        await sut.loadTask?.value
        #expect(await repository.searchedQueries.count == 2)
    }

    @Test("Listen picks the newest episode by date")
    func newestEpisode() async {
        let old = Episode(title: "Old", author: "", pubDate: Date(timeIntervalSince1970: 10), description: "", streamUrl: "a")
        let new = Episode(title: "New", author: "", pubDate: Date(timeIntervalSince1970: 20), description: "", streamUrl: "b")
        let repository = MockSearchPodcastRepository(episodes: [old, new])
        let sut = GenreRankingViewModel(genre: science, repository: repository)

        let episode = await sut.newestEpisode(of: Fixtures.podcast())

        #expect(episode?.title == "New")
        #expect(sut.preparingPodcastID == nil)
    }
}
