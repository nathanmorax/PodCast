//
//  PodcastSearchViewModelTests.swift
//  PodcastTests
//

import Testing
@testable import Podcast

/// @MainActor because the view model is main-actor isolated.
@MainActor
@Suite("PodcastSearchViewModel")
struct PodcastSearchViewModelTests {

    @Test("Rapid keystrokes trigger a single search with the latest text")
    func debounceCoalescesKeystrokes() async {
        let repository = MockSearchPodcastRepository(podcasts: [Fixtures.podcast()])
        let sut = PodcastSearchViewModel(repository: repository, debounce: .milliseconds(1))

        sut.search("s")
        sut.search("sw")
        sut.search("swift")
        await sut.searchTask?.value

        #expect(await repository.searchedQueries == ["swift"])
        #expect(sut.podcasts.count == 1)
        #expect(sut.error == nil)
    }

    @Test("Searching the same text twice only hits the repository once")
    func duplicateQueryIsSkipped() async {
        let repository = MockSearchPodcastRepository(podcasts: [Fixtures.podcast()])
        let sut = PodcastSearchViewModel(repository: repository, debounce: .milliseconds(1))

        sut.search("swift")
        await sut.searchTask?.value
        sut.search("swift")
        await sut.searchTask?.value

        #expect(await repository.searchedQueries == ["swift"])
    }

    @Test("Clearing the text cancels a pending search")
    func emptyTextCancelsPendingSearch() async {
        let repository = MockSearchPodcastRepository(podcasts: [Fixtures.podcast()])
        let sut = PodcastSearchViewModel(repository: repository, debounce: .milliseconds(50))

        sut.search("swi")
        let pending = sut.searchTask
        sut.search("")
        await pending?.value

        #expect(await repository.searchedQueries.isEmpty)
        #expect(sut.podcasts.isEmpty)
    }

    @Test("A failing search exposes an error message")
    func failureSetsError() async {
        let repository = MockSearchPodcastRepository(error: TestError())
        let sut = PodcastSearchViewModel(repository: repository, debounce: .milliseconds(1))

        sut.search("swift")
        await sut.searchTask?.value

        #expect(sut.error != nil)
        #expect(sut.podcasts.isEmpty)
    }

    @Test("A query that failed can be retried")
    func failedQueryIsNotTreatedAsDuplicate() async {
        let repository = MockSearchPodcastRepository(error: TestError())
        let sut = PodcastSearchViewModel(repository: repository, debounce: .milliseconds(1))

        sut.search("swift")
        await sut.searchTask?.value
        sut.search("swift")
        await sut.searchTask?.value

        #expect(await repository.searchedQueries == ["swift", "swift"])
    }
}
