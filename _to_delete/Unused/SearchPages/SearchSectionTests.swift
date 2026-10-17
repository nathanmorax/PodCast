//
//  SearchSectionTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

@Suite("SearchSection & LocalSearch")
struct SearchSectionTests {

    private func podcast(_ id: Int, _ name: String, artist: String? = nil, genre: String? = nil) -> Podcast {
        Podcast(trackId: id, trackName: name, artistName: artist, artworkUrl600: nil,
                primaryGenreName: genre, trackCount: nil, feedUrl: nil)
    }

    private func episode(_ title: String, author: String = "Autor") -> Episode {
        Episode(title: title, author: author, pubDate: .now, description: "",
                streamUrl: "https://example.com/\(title.hashValue).mp3")
    }

    @Test("Only the Search page asks the catalog")
    func onlyExploreSearchesCatalog() {
        #expect(SearchSection.explore.searchesCatalog)
        #expect(!SearchSection.following.searchesCatalog)
        #expect(!SearchSection.favorites.searchesCatalog)
    }

    @Test("Pages are in picker order: Search · Following · Favorites")
    func order() {
        #expect(SearchSection.allCases == [.explore, .following, .favorites])
    }

    @Test("An empty or blank query keeps everything", arguments: ["", "   "])
    func emptyQueryKeepsAll(query: String) {
        let all = [podcast(1, "Átomo"), podcast(2, "Café con Datos")]
        #expect(LocalSearch.podcasts(all, matching: query).map(\.trackId) == [1, 2])
    }

    @Test("Ignores case and accents")
    func caseAndAccentInsensitive() {
        let all = [podcast(1, "Átomo"), podcast(2, "Café con Datos")]
        #expect(LocalSearch.podcasts(all, matching: "atomo").map(\.trackId) == [1])
        #expect(LocalSearch.podcasts(all, matching: "CAFE").map(\.trackId) == [2])
    }

    @Test("Podcasts match by artist and genre too")
    func podcastFields() {
        let all = [podcast(1, "Átomo", artist: "Radio Ciencia", genre: "Science"),
                   podcast(2, "Risas", artist: "Comedia MX", genre: "Comedy")]
        #expect(LocalSearch.podcasts(all, matching: "ciencia").map(\.trackId) == [1])
        #expect(LocalSearch.podcasts(all, matching: "comedy").map(\.trackId) == [2])
    }

    @Test("Episodes match by title or author")
    func episodeFields() {
        let all = [episode("Las plantas se comunican", author: "Átomo"),
                   episode("El costo de decidir", author: "Café con Datos")]
        #expect(LocalSearch.episodes(all, matching: "plantas").map(\.title) == ["Las plantas se comunican"])
        #expect(LocalSearch.episodes(all, matching: "cafe").map(\.title) == ["El costo de decidir"])
        #expect(LocalSearch.episodes(all, matching: "nada").isEmpty)
    }
}
