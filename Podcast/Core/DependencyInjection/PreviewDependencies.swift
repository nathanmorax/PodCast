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

extension PlayerManager {
    static var preview: PlayerManager {
        PlayerManager(downloadManager: .preview, recentlyPlayed: .preview)
    }
}
#endif
