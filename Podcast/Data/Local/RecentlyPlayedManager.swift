//
//  RecentlyPlayedManager.swift
//  Podcast
//

import Foundation
import Observation

/// Remembers the last episodes played (most recent first) in UserDefaults.
@MainActor
@Observable
final class RecentlyPlayedManager {

    static let shared = RecentlyPlayedManager()

    private(set) var items: [RecentlyPlayed] = []

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let limit: Int
    @ObservationIgnored private let key = "recently_played_episodes"

    init(userDefaults: UserDefaults = .standard, limit: Int = 20) {
        self.userDefaults = userDefaults
        self.limit = limit
        self.items = load()
    }

    /// Moves the episode to the top (or adds it), keeping its saved progress.
    func record(_ episode: Episode, at date: Date = .now) {
        let previous = items.first { $0.id == episode.streamUrl }
        items.removeAll { $0.id == episode.streamUrl }
        items.insert(
            RecentlyPlayed(episode: episode, lastPlayedAt: date, progress: previous?.progress ?? 0),
            at: 0
        )
        if items.count > limit {
            items.removeLast(items.count - limit)
        }
        save()
    }

    func updateProgress(for episode: Episode, progress: Double) {
        guard let index = items.firstIndex(where: { $0.id == episode.streamUrl }) else { return }
        items[index].progress = min(max(progress, 0), 1)
        save()
    }

    func remove(_ item: RecentlyPlayed) {
        items.removeAll { $0.id == item.id }
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        userDefaults.set(data, forKey: key)
    }

    private func load() -> [RecentlyPlayed] {
        guard let data = userDefaults.data(forKey: key),
              let items = try? JSONDecoder().decode([RecentlyPlayed].self, from: data) else {
            return []
        }
        return items
    }
}
