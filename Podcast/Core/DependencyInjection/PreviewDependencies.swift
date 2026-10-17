//
//  PreviewDependencies.swift
//  Podcast
//

#if DEBUG
import Foundation

/// Isolated instances for #Preview: no real UserDefaults, Documents folder or network state.
extension DownloadManager {
    static var preview: DownloadManager {
        DownloadManager(
            userDefaults: UserDefaults(suiteName: "preview.downloads") ?? .standard,
            downloadsDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("PreviewDownloads", isDirectory: true)
        )
    }
}

extension RecentlyPlayedManager {
    /// Pre-filled with the mock episodes so the Library preview has content.
    static var preview: RecentlyPlayedManager {
        let manager = RecentlyPlayedManager(userDefaults: UserDefaults(suiteName: "preview.recent") ?? .standard)
        for (offset, episode) in Episode.mocks.enumerated().reversed() {
            manager.record(episode, at: Date.now.addingTimeInterval(Double(-offset) * 3_600 * 5))
        }
        return manager
    }
}

extension RecentSearchesManager {
    /// A few searched podcasts so the Search preview has a recent row.
    static var preview: RecentSearchesManager {
        let manager = RecentSearchesManager(userDefaults: UserDefaults(suiteName: "preview.searches") ?? .standard)
        manager.clear()
        let names = ["Hidden Brain", "Radio Ambulante", "Café con Datos", "Historias Lentas"]
        for (offset, name) in names.enumerated().reversed() {
            manager.record(Podcast(
                trackId: offset + 1,
                trackName: name,
                artistName: Podcast.mock.artistName,
                artworkUrl600: Podcast.mock.artworkUrl600,
                primaryGenreName: Podcast.mock.primaryGenreName,
                trackCount: Podcast.mock.trackCount,
                feedUrl: Podcast.mock.feedUrl
            ))
        }
        return manager
    }
}

extension FavoritesPodcastManager {
    /// Two favorite podcasts for the Home preview.
    static var preview: FavoritesPodcastManager {
        let manager = FavoritesPodcastManager(userDefaults: UserDefaults(suiteName: "preview.favorites") ?? .standard)
        for podcast in RecentSearchesManager.preview.items.prefix(2) where !manager.isFavorite(podcast) {
            manager.toggleFavorite(podcast)
        }
        return manager
    }
}

extension PlayerManager {
    static var preview: PlayerManager {
        PlayerManager(downloadManager: .preview, recentlyPlayed: .preview)
    }
}
extension InterestsManager {
    /// Onboarding already done, with three genres chosen.
    static var preview: InterestsManager {
        let manager = InterestsManager(userDefaults: UserDefaults(suiteName: "preview.interests") ?? .standard)
        manager.save(["1303", "1533", "1488"])
        return manager
    }
}

#endif
