//
//  InterestsManagerTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

@MainActor
@Suite("InterestsManager")
struct InterestsManagerTests {

    private let defaults = UserDefaults.isolated()

    @Test("First launch needs onboarding")
    func firstLaunch() {
        let sut = InterestsManager(userDefaults: defaults)
        #expect(sut.needsOnboarding)
        #expect(sut.genres.isEmpty)
    }

    @Test("Saving keeps the order, maps to catalog genres and persists")
    func save() {
        let sut = InterestsManager(userDefaults: defaults)
        sut.save(["1533", "1303", "1488"])

        #expect(!sut.needsOnboarding)
        #expect(sut.genres.map(\.id) == ["1533", "1303", "1488"])

        let reloaded = InterestsManager(userDefaults: defaults)
        #expect(reloaded.genreIDs == ["1533", "1303", "1488"])
        #expect(!reloaded.needsOnboarding)
    }

    @Test("Skip finishes onboarding without choosing anything")
    func skip() {
        let sut = InterestsManager(userDefaults: defaults)
        sut.skip()
        #expect(!sut.needsOnboarding)
        #expect(sut.genreIDs.isEmpty)
    }

    @Test("Edit reopens the screen; skipping keeps the old picks")
    func edit() {
        let sut = InterestsManager(userDefaults: defaults)
        sut.save(["1303", "1489", "1533"])
        sut.edit()
        #expect(sut.needsOnboarding)
        sut.skip()
        #expect(!sut.needsOnboarding)
        #expect(sut.genreIDs == ["1303", "1489", "1533"])
    }

    @Test("Unknown ids are ignored")
    func unknownIDs() {
        let sut = InterestsManager(userDefaults: defaults)
        sut.save(["1303", "nope"])
        #expect(sut.genres.map(\.id) == ["1303"])
    }

    @Test("Listening adds the podcast's genre once, after the picked ones")
    func learn() {
        let sut = InterestsManager(userDefaults: defaults)
        sut.save(["1303"])
        sut.learn(genreID: "1533")
        sut.learn(genreID: "1533")
        #expect(sut.genreIDs == ["1303", "1533"])
        #expect(InterestsManager(userDefaults: defaults).genreIDs == ["1303", "1533"])
    }

    @Test("Nothing is learned before onboarding is done")
    func learnBeforeOnboarding() {
        let sut = InterestsManager(userDefaults: defaults)
        sut.learn(genreID: "1533")
        #expect(sut.genreIDs.isEmpty)
    }

    @Test("iTunes genre names map to the catalog, subgenres to their parent")
    func iTunesNames() {
        #expect(Genre.catalogID(forITunesGenre: "Comedy") == "1303")
        #expect(Genre.catalogID(forITunesGenre: "Improv") == "1303")
        #expect(Genre.catalogID(forITunesGenre: "True Crime") == "1488")
        #expect(Genre.catalogID(forITunesGenre: "Underwater Basket Weaving") == nil)
        #expect(Genre.catalogID(forITunesGenre: nil) == nil)
    }
}
