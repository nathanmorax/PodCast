//
//  LibraryTabTests.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

@Suite("LibraryTab")
struct LibraryTabTests {

    private func episode(_ url: String, at seconds: TimeInterval) -> Episode {
        Episode(title: url, author: "Author", pubDate: Date(timeIntervalSince1970: seconds),
                description: "", streamUrl: url)
    }

    @Test("New keeps each episode's show")
    func newKeepsShow() {
        let new = [PodcastEpisode(podcast: .mock, episode: episode("n", at: 3))]
        let items = LibraryTab.new.items(new: new, saved: [], downloads: [], history: [])
        #expect(items.first?.showName == Podcast.mock.trackName)
    }

    @Test("Saved and Downloads use the author as the show")
    func bareEpisodes() {
        let items = LibraryTab.saved.items(new: [], saved: [episode("a", at: 1)], downloads: [], history: [])
        #expect(items.map(\.showName) == ["Author"])
    }

    @Test("History lists the last played first")
    func historyByLastPlayed() {
        let history = [
            RecentlyPlayed(episode: episode("older", at: 1), lastPlayedAt: Date(timeIntervalSince1970: 10), progress: 1),
            RecentlyPlayed(episode: episode("latest", at: 2), lastPlayedAt: Date(timeIntervalSince1970: 20), progress: 0.4)
        ]
        let items = LibraryTab.history.items(new: [], saved: [], downloads: [], history: history)
        #expect(items.map(\.id) == ["latest", "older"])
    }

    @Test("Each tab lists only its own")
    func tabsAreSeparate() {
        let new = [PodcastEpisode(podcast: .mock, episode: episode("n", at: 3))]
        let saved = [episode("s", at: 2)]
        let downloads = [episode("d", at: 1)]
        let history = [RecentlyPlayed(episode: episode("h", at: 0), lastPlayedAt: .now, progress: 0.5)]
        func ids(_ tab: LibraryTab) -> [String] {
            tab.items(new: new, saved: saved, downloads: downloads, history: history).map(\.id)
        }
        #expect(ids(.new) == ["n"])
        #expect(ids(.saved) == ["s"])
        #expect(ids(.downloads) == ["d"])
        #expect(ids(.history) == ["h"])
    }
}
