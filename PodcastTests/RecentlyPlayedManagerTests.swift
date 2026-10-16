//
//  RecentlyPlayedManagerTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

@MainActor
struct RecentlyPlayedManagerTests {

    private let first = Fixtures.episode(streamUrl: "https://example.com/1.mp3", title: "Uno")
    private let second = Fixtures.episode(streamUrl: "https://example.com/2.mp3", title: "Dos")

    @Test("The last episode played goes first")
    func newestFirst() {
        let sut = RecentlyPlayedManager(userDefaults: .isolated())

        sut.record(first)
        sut.record(second)

        #expect(sut.items.map(\.id) == [second.streamUrl, first.streamUrl])
    }

    @Test("Playing an episode again moves it up without losing its progress")
    func recordAgainKeepsProgress() {
        let sut = RecentlyPlayedManager(userDefaults: .isolated())
        sut.record(first)
        sut.updateProgress(for: first, progress: 0.4)
        sut.record(second)

        sut.record(first)

        #expect(sut.items.map(\.id) == [first.streamUrl, second.streamUrl])
        #expect(sut.items.first?.progress == 0.4)
    }

    @Test("Progress stays between 0 and 1", arguments: [(-0.5, 0.0), (0.25, 0.25), (1.7, 1.0)])
    func progressIsClamped(input: Double, expected: Double) {
        let sut = RecentlyPlayedManager(userDefaults: .isolated())
        sut.record(first)

        sut.updateProgress(for: first, progress: input)

        #expect(sut.items.first?.progress == expected)
    }

    @Test("Updating an episode that isn't in the list does nothing")
    func updateUnknownEpisode() {
        let sut = RecentlyPlayedManager(userDefaults: .isolated())
        sut.record(first)

        sut.updateProgress(for: second, progress: 0.9)

        #expect(sut.items.count == 1)
        #expect(sut.items.first?.progress == 0)
    }

    @Test("Only the most recent episodes up to the limit are kept")
    func limit() {
        let sut = RecentlyPlayedManager(userDefaults: .isolated(), limit: 3)

        for episode in Fixtures.episodes(count: 5) {
            sut.record(episode)
        }

        #expect(sut.items.map(\.episode.title) == ["Episode 4", "Episode 3", "Episode 2"])
    }

    @Test("An episode can be removed from the list")
    func remove() throws {
        let sut = RecentlyPlayedManager(userDefaults: .isolated())
        sut.record(first)
        sut.record(second)

        sut.remove(try #require(sut.items.first))

        #expect(sut.items.map(\.id) == [first.streamUrl])
    }

    @Test("The history survives a relaunch")
    func persistence() {
        let defaults = UserDefaults.isolated()
        let before = RecentlyPlayedManager(userDefaults: defaults)
        before.record(first)
        before.updateProgress(for: first, progress: 0.6)

        let relaunched = RecentlyPlayedManager(userDefaults: defaults)

        #expect(relaunched.items.map(\.id) == [first.streamUrl])
        #expect(relaunched.items.first?.progress == 0.6)
    }
}
