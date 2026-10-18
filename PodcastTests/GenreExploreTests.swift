//
//  GenreExploreTests.swift
//  PodcastTests
//

import Testing
@testable import Podcast

@Suite("Genre.explore")
struct GenreExploreTests {

    @Test("Interests come first, in their order, and nothing repeats")
    func interestsFirst() {
        let science = Genre.catalog(id: "1533")!
        let news = Genre.catalog(id: "1489")!

        let result = Genre.explore(interests: [science, news])

        #expect(result.prefix(2).map(\.id) == ["1533", "1489"])
        #expect(result.count == Genre.podcastCatalog.count)
        #expect(Set(result.map(\.id)).count == result.count)
    }

    @Test("With no interests it's the catalog as is")
    func noInterests() {
        #expect(Genre.explore(interests: []) == Genre.podcastCatalog)
    }
}
