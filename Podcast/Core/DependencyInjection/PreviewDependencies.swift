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

extension PlayerManager {
    static var preview: PlayerManager {
        PlayerManager(downloadManager: .preview)
    }
}
#endif
