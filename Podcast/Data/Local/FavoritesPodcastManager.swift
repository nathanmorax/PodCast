//
//  FavoritesPodcastManager.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//

import Foundation
import Observation

/// The podcasts the listener marked as favorite, saved in UserDefaults.
///
/// @MainActor @Observable, like RecentlyPlayedManager: it's UI state, and
/// SwiftUI views and UIKit screens (automatic observation) update by just
/// reading `favorites`. Replaces the Combine `CurrentValueSubject` it used.
@MainActor
@Observable
final class FavoritesPodcastManager {

    static let shared = FavoritesPodcastManager()

    private(set) var favorites: [Podcast]

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let key = "favorite_podcasts"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.favorites = Self.load(from: userDefaults, key: "favorite_podcasts")
    }

    func toggleFavorite(_ podcast: Podcast) {
        if isFavorite(podcast) {
            favorites.removeAll { $0.trackId == podcast.trackId }
        } else {
            favorites.append(podcast)
        }
        save()
    }

    func isFavorite(_ podcast: Podcast) -> Bool {
        favorites.contains { $0.trackId == podcast.trackId }
    }

    func deleteFavorite(_ podcast: Podcast) {
        favorites.removeAll { $0.trackId == podcast.trackId }
        save()
    }

    // MARK: - Persistence

    private func save() {
        do {
            userDefaults.set(try JSONEncoder().encode(favorites), forKey: key)
        } catch {
            print("❌ Error encoding favorites:", error)
        }
    }

    private static func load(from userDefaults: UserDefaults, key: String) -> [Podcast] {
        guard let data = userDefaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Podcast].self, from: data)) ?? []
    }
}
