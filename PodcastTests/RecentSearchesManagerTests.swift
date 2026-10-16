//
//  RecentSearchesManagerTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

@MainActor
struct RecentSearchesManagerTests {

    @Test func recordPutsTheNewestFirst() {
        let sut = RecentSearchesManager(userDefaults: .isolated())

        sut.record(Fixtures.podcast(id: 1))
        sut.record(Fixtures.podcast(id: 2))

        #expect(sut.items.map(\.trackId) == [2, 1])
    }

    @Test func recordingAgainMovesItToTheFrontWithoutDuplicating() {
        let sut = RecentSearchesManager(userDefaults: .isolated())
        sut.record(Fixtures.podcast(id: 1))
        sut.record(Fixtures.podcast(id: 2))

        sut.record(Fixtures.podcast(id: 1))

        #expect(sut.items.map(\.trackId) == [1, 2])
    }

    @Test func keepsOnlyTheMostRecentUpToTheLimit() {
        let sut = RecentSearchesManager(userDefaults: .isolated(), limit: 3)

        for id in 1...5 {
            sut.record(Fixtures.podcast(id: id))
        }

        #expect(sut.items.map(\.trackId) == [5, 4, 3])
    }

    @Test func removeAndClear() {
        let sut = RecentSearchesManager(userDefaults: .isolated())
        sut.record(Fixtures.podcast(id: 1))
        sut.record(Fixtures.podcast(id: 2))

        sut.remove(Fixtures.podcast(id: 1))
        #expect(sut.items.map(\.trackId) == [2])

        sut.clear()
        #expect(sut.items.isEmpty)
    }

    @Test func survivesARelaunch() {
        let defaults = UserDefaults.isolated()
        RecentSearchesManager(userDefaults: defaults).record(Fixtures.podcast(id: 7, name: "Radio Ambulante"))

        let relaunched = RecentSearchesManager(userDefaults: defaults)

        #expect(relaunched.items.map(\.trackId) == [7])
        #expect(relaunched.items.first?.trackName == "Radio Ambulante")
    }
}
