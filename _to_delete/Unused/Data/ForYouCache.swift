//
//  ForYouCache.swift
//  Podcast
//

import Foundation

/// The last "For you" episodes, saved on the phone, so Library shows them the
/// moment it opens (even after the app was closed) while the feeds refresh.
///
/// Keeps only what the row can show (a few per podcast) and drops the long
/// show notes: it's a small JSON in UserDefaults, read once at launch.
///
/// @MainActor like the other local stores: only Library's view model uses it,
/// and it makes `standard` safe to share under Swift 6.
@MainActor
struct ForYouCache {

    private let userDefaults: UserDefaults
    private let key = "for_you_latest_episodes"

    /// Episodes kept per podcast.
    let perPodcast: Int

    /// - Parameter perPodcast: the same as `ForYouViewModel.perPodcast` (the
    ///   row never shows more than that from one podcast).
    init(userDefaults: UserDefaults = .standard, perPodcast: Int = 2) {
        self.userDefaults = userDefaults
        self.perPodcast = perPodcast
    }

    static let standard = ForYouCache()

    /// Podcast trackId → its newest episodes. Empty when nothing was saved.
    func load() -> [Int: [Episode]] {
        guard let data = userDefaults.data(forKey: key),
              let stored = try? JSONDecoder().decode([String: [Episode]].self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: stored.compactMap { key, episodes in
            Int(key).map { ($0, episodes) }
        })
    }

    func save(_ episodesByPodcast: [Int: [Episode]]) {
        let trimmed = Dictionary(uniqueKeysWithValues: episodesByPodcast.map { id, episodes in
            let newest = episodes
                .sorted { $0.pubDate > $1.pubDate }
                .prefix(perPodcast)
                .map { episode -> Episode in
                    var light = episode
                    light.showNotes = nil
                    return light
                }
            return (String(id), Array(newest))
        })
        guard let data = try? JSONEncoder().encode(trimmed) else { return }
        userDefaults.set(data, forKey: key)
    }
}
