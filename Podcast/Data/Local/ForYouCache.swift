//
//  ForYouCache.swift
//  Podcast
//

import Foundation

/// The last "For you" row, saved on the phone, so Library shows it the
/// moment it opens (even after the app was killed) while a fresh one is
/// fetched behind it. Like Apple Podcasts: what you saw last time stays on
/// screen and updates in place; no blank gap at launch.
///
/// Saved with the interests it was made for: if they changed, it's not
/// shown. Small: a few episodes, without their long show notes.
@MainActor
struct ForYouCache {

    struct Saved: Codable {
        /// The interests' ids it was made for ("1489,1303").
        let key: String
        let items: [PodcastEpisode]
    }

    private let userDefaults: UserDefaults
    private let storageKey = "for_you_discovery"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    static let standard = ForYouCache()

    func load() -> Saved? {
        guard let data = userDefaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(Saved.self, from: data)
    }

    func save(_ items: [PodcastEpisode], key: String) {
        let light = items.map { item -> PodcastEpisode in
            var episode = item.episode
            episode.showNotes = nil
            return PodcastEpisode(podcast: item.podcast, episode: episode)
        }
        guard let data = try? JSONEncoder().encode(Saved(key: key, items: light)) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
