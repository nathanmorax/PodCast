//
//  EpisodesViewModelTests.swift
//  PodcastTests
//

import Testing
@testable import Podcast

@MainActor
@Suite("EpisodesViewModel")
struct EpisodesViewModelTests {

    /// A new instance per test: Swift Testing creates the suite once per @Test.
    let favorites = FavoritesPodcastManager(userDefaults: .isolated())

    private func makeSUT(episodes: [Episode] = [], error: Error? = nil) -> (EpisodesViewModel, MockSearchPodcastRepository) {
        let repository = MockSearchPodcastRepository(episodes: episodes, error: error)
        return (EpisodesViewModel(repository: repository, favoritesManager: favorites), repository)
    }

    @Test("The first load shows only the first page")
    func firstLoadShowsFirstPage() async {
        let (sut, repository) = makeSUT(episodes: Fixtures.episodes(count: 45))

        sut.loadEpisodes(feedURL: "https://example.com/feed")
        #expect(sut.isLoadingEpisodes)
        await sut.loadEpisodesTask?.value

        #expect(sut.episodes.count == 20)
        #expect(sut.isLoadingEpisodes == false)
        #expect(await repository.fetchedFeeds == ["https://example.com/feed"])
    }

    @Test("loadMoreEpisodes appends pages and stops at the end",
          arguments: [
            (total: 45, extraPages: 1, expected: 40),
            (total: 45, extraPages: 2, expected: 45),
            (total: 45, extraPages: 5, expected: 45),
            (total: 10, extraPages: 1, expected: 10),
            (total: 0,  extraPages: 1, expected: 0),
          ])
    func pagination(total: Int, extraPages: Int, expected: Int) async {
        let (sut, _) = makeSUT(episodes: Fixtures.episodes(count: total))
        sut.loadEpisodes(feedURL: "feed")
        await sut.loadEpisodesTask?.value

        for _ in 0..<extraPages { sut.loadMoreEpisodes() }

        #expect(sut.episodes.count == expected)
    }

    @Test("Reloading replaces the list instead of appending to it")
    func reloadReplacesEpisodes() async {
        let (sut, _) = makeSUT(episodes: Fixtures.episodes(count: 45))

        sut.loadEpisodes(feedURL: "feed")
        await sut.loadEpisodesTask?.value
        sut.loadEpisodes(feedURL: "feed")
        await sut.loadEpisodesTask?.value

        #expect(sut.episodes.count == 20)
        #expect(sut.episodes.first?.title == "Episode 0")
    }

    @Test("A fetch error shows a message and stops the loader")
    func failureShowsError() async {
        let (sut, _) = makeSUT(error: TestError())

        sut.loadEpisodes(feedURL: "feed")
        await sut.loadEpisodesTask?.value

        #expect(sut.errorMessage != nil)
        #expect(sut.isLoadingEpisodes == false)
        #expect(sut.episodes.isEmpty)
    }

    @Test("toggleFavorite adds and removes through the injected manager")
    func toggleFavorite() {
        let (sut, _) = makeSUT()
        let podcast = Fixtures.podcast()

        sut.toggleFavorite(podcast: podcast)
        #expect(sut.isFavorite(podcast))

        sut.toggleFavorite(podcast: podcast)
        #expect(sut.isFavorite(podcast) == false)
    }

    @Test("Episodes and the description come from a single download of the feed")
    func oneDownloadForEpisodesAndDescription() async {
        let (sut, repository) = makeSUT(episodes: Fixtures.episodes(count: 3))

        sut.loadEpisodes(feedURL: "feed")
        #expect(sut.isLoadingDescription)
        await sut.loadEpisodesTask?.value

        #expect(sut.podcastDescription == "A show about tests")
        #expect(sut.isLoadingDescription == false)
        #expect(sut.episodes.count == 3)
        #expect(await repository.fetchedFeeds.count == 1)
    }

    @Test("favorites follows the manager")
    func favoritesFollowManager() {
        let (sut, _) = makeSUT()
        let podcast = Fixtures.podcast()

        favorites.toggleFavorite(podcast)

        #expect(sut.favorites.map(\.trackId) == [podcast.trackId])
    }
}
