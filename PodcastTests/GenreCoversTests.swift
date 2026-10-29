//
//  GenreCoversTests.swift
//  PodcastTests
//

import Testing
@testable import Podcast

@Suite("GenreCovers")
struct GenreCoversTests {

    private func podcast(_ id: Int, art: String?) -> Podcast {
        Podcast(trackId: id, trackName: "\(id)", artistName: nil, artworkUrl600: art,
                primaryGenreName: nil, trackCount: nil, feedUrl: nil)
    }

    @Test("Takes the first covers, up to the limit")
    func limit() {
        let covers = GenreCovers.artwork(from: [podcast(1, art: "a"), podcast(2, art: "b"), podcast(3, art: "c")])
        #expect(covers == ["a", "b"])
    }

    @Test("Skips blanks and repeats")
    func skipsBlanks() {
        let covers = GenreCovers.artwork(from: [podcast(1, art: nil), podcast(2, art: ""), podcast(3, art: "a"),
                                                podcast(4, art: "a"), podcast(5, art: "b")])
        #expect(covers == ["a", "b"])
    }
}
