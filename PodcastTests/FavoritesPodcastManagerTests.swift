//
//  FavoritesPodcastManagerTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

@MainActor
struct FavoritesPodcastManagerTests {

    @Test("Toggling adds a podcast, and toggling again removes it")
    func toggle() {
        let sut = FavoritesPodcastManager(userDefaults: .isolated())
        let podcast = Fixtures.podcast(id: 1)

        sut.toggleFavorite(podcast)
        #expect(sut.isFavorite(podcast))
        #expect(sut.favorites.count == 1)

        sut.toggleFavorite(podcast)
        #expect(!sut.isFavorite(podcast))
        #expect(sut.favorites.isEmpty)
    }

    @Test("Favorites survive a relaunch")
    func persistence() {
        let defaults = UserDefaults.isolated()
        FavoritesPodcastManager(userDefaults: defaults).toggleFavorite(Fixtures.podcast(id: 7))

        let relaunched = FavoritesPodcastManager(userDefaults: defaults)

        #expect(relaunched.favorites.map(\.trackId) == [7])
    }

    @Test("deleteFavorite removes only that podcast")
    func delete() {
        let sut = FavoritesPodcastManager(userDefaults: .isolated())
        sut.toggleFavorite(Fixtures.podcast(id: 1))
        sut.toggleFavorite(Fixtures.podcast(id: 2))

        sut.deleteFavorite(Fixtures.podcast(id: 1))

        #expect(sut.favorites.map(\.trackId) == [2])
    }
}
