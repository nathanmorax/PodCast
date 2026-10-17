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
}
