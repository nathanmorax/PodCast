//
//  RecentSearchesManager.swift
//  Podcast
//

import Foundation
import Observation

/// Podcasts opened from Search, most recent first. Shown in
/// "Buscado recientemente" and saved in UserDefaults.
@MainActor
@Observable
final class RecentSearchesManager {

    static let shared = RecentSearchesManager()

    private(set) var items: [Podcast] = []

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let limit: Int
    @ObservationIgnored private let key = "recent_searched_podcasts"

    init(userDefaults: UserDefaults = .standard, limit: Int = 12) {
        self.userDefaults = userDefaults
        self.limit = limit
        self.items = load()
    }

    /// Moves the podcast to the front (or adds it there).
    func record(_ podcast: Podcast) {
        items.removeAll { $0.trackId == podcast.trackId }
        items.insert(podcast, at: 0)
        if items.count > limit {
            items.removeLast(items.count - limit)
        }
        save()
    }

    func remove(_ podcast: Podcast) {
        items.removeAll { $0.trackId == podcast.trackId }
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        userDefaults.set(data, forKey: key)
    }

    private func load() -> [Podcast] {
        guard let data = userDefaults.data(forKey: key),
              let items = try? JSONDecoder().decode([Podcast].self, from: data) else {
            return []
        }
        return items
    }
}
