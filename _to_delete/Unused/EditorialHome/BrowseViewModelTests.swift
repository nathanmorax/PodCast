//
//  BrowseViewModelTests.swift
//  PodcastTests
//

import Testing
@testable import Podcast

@MainActor
@Suite("BrowseViewModel")
struct BrowseViewModelTests {

    private let science = Genre.catalog(id: "1533")!
    private let comedy = Genre.catalog(id: "1303")!

    @Test("Chips: Picked for you, then the interests")
    func chipsFromInterests() {
        let chips = BrowseViewModel.chips(interests: [science, comedy])
        #expect(chips == [.pickedForYou, .genre(science), .genre(comedy)])
    }

    @Test("No interests: the most listened categories")
    func chipsWithoutInterests() {
        let chips = BrowseViewModel.chips(interests: [])
        #expect(chips.first == .pickedForYou)
        #expect(chips.count == BrowseViewModel.defaultChips + 1)
    }

    @Test("A category searches its name once")
    func categoryLoadsOnce() async {
        let repository = MockSearchPodcastRepository(podcasts: [Fixtures.podcast(id: 1), Fixtures.podcast(id: 2)])
        let sut = BrowseViewModel(repository: repository)

        await sut.load(.genre(science), interests: [])
        await sut.load(.genre(science), interests: [])

        #expect(sut.podcasts(for: .genre(science)).map(\.trackId) == [1, 2])
        #expect(await repository.searchedQueries == [science.name])
    }

    @Test("Picked for you searches the first interests and never repeats a show")
    func pickedForYou() async {
        // The fake answers the same shows for every search: each shows up once.
        let repository = MockSearchPodcastRepository(podcasts: [Fixtures.podcast(id: 1), Fixtures.podcast(id: 2)])
        let sut = BrowseViewModel(repository: repository)

        await sut.load(.pickedForYou, interests: [science, comedy])

        #expect(await repository.searchedQueries == [science.name, comedy.name])
        #expect(sut.podcasts(for: .pickedForYou).map(\.trackId) == [1, 2])
    }

    @Test("A failed search can be retried")
    func failure() async {
        let sut = BrowseViewModel(repository: MockSearchPodcastRepository(error: TestError()))

        await sut.load(.genre(comedy), interests: [])

        #expect(sut.failed.contains(.genre(comedy)))
        #expect(sut.podcasts(for: .genre(comedy)).isEmpty)
    }
}
