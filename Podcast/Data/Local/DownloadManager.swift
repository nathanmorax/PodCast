//
//  DownloadManager.swift
//  Podcast
//
//  Created by Jonathan Mora on 04/06/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class DownloadManager {

    static let shared = DownloadManager()

    /// Dependencies are injectable so tests and previews never touch the real
    /// Documents folder, UserDefaults.standard or the network.
    init(
        userDefaults: UserDefaults = .standard,
        session: URLSession = .shared,
        downloadsDirectory: URL = DownloadManager.defaultDownloadsDirectory
    ) {
        self.userDefaults = userDefaults
        self.session = session
        self.downloadsDirectory = downloadsDirectory
        loadPersistedEpisodes()
    }

    nonisolated static var defaultDownloadsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Downloads", isDirectory: true)
    }

    private(set) var states: [String: DownloadState] = [:]
    var downloadedEpisodes: [Episode] = []

    @ObservationIgnored
    private var activeTasks: [String: URLSessionDownloadTask] = [:]

    @ObservationIgnored
    private let userDefaults: UserDefaults

    @ObservationIgnored
    private let session: URLSession

    @ObservationIgnored
    private let downloadsDirectory: URL

    @ObservationIgnored
    private let episodesKey = "downloaded_episodes_metadata"

    // MARK: - API pública

    func state(for episode: Episode) -> DownloadState {
        states[episode.streamUrl] ?? .idle
    }

    func download(_ episode: Episode) {
        // .failed is allowed too, so the user can retry after an error.
        switch state(for: episode) {
        case .idle, .failed: break
        default: return
        }
        guard let url = URL(string: episode.streamUrl) else { return }

        let key = episode.streamUrl
        let destination = fileURL(for: episode)
        states[key] = .downloading(progress: 0)

        // This completion handler runs on a URLSession background queue,
        // NOT on the main actor.
        let task = session.downloadTask(with: url) { @Sendable [weak self] tempURL, _, error in
            guard let self else { return }

            if let error {
                // cancelDownload() already set the state to .idle; don't overwrite it with .failed.
                if (error as? URLError)?.code == .cancelled { return }
                let message = error.localizedDescription
                Task { @MainActor in
                    self.activeTasks[key] = nil
                    self.states[key] = .failed(message)
                }
                return
            }

            guard let tempURL else { return }

            // The temp file is deleted as soon as this closure returns, so the
            // move must happen here, off the main actor (moveToDocuments is nonisolated).
            let result = Result { try Self.moveFile(from: tempURL, to: destination) }

            Task { @MainActor in
                self.activeTasks[key] = nil
                switch result {
                case .success(let localURL):
                    self.states[key] = .downloaded(localURL: localURL)
                    self.persistEpisode(episode)
                case .failure(let error):
                    self.states[key] = .failed(error.localizedDescription)
                }
            }
        }

        // @Sendable: KVO calls this on URLSession's queue. Without it, the
        // closure would be inferred @MainActor (this class is) and crash on
        // the first progress tick.
        let observation = task.progress.observe(\.fractionCompleted) { @Sendable [weak self] progress, _ in
            let fraction = progress.fractionCompleted
            Task { @MainActor in
                // A late progress tick must not revert .downloaded / .idle back to .downloading.
                guard let self, case .downloading = self.state(for: episode) else { return }
                self.states[key] = .downloading(progress: fraction)
            }
        }
        objc_setAssociatedObject(task, "observation", observation, .OBJC_ASSOCIATION_RETAIN)

        activeTasks[key] = task
        task.resume()
    }

    func cancelDownload(_ episode: Episode) {
        activeTasks[episode.streamUrl]?.cancel()
        activeTasks[episode.streamUrl] = nil
        states[episode.streamUrl] = .idle
    }

    func deleteDownload(_ episode: Episode) {
        // Read the file URL BEFORE cancelDownload() resets the state to .idle;
        // otherwise this check never matched and the .mp3 stayed on disk.
        let localURL = localURL(for: episode)
        cancelDownload(episode)

        if let localURL {
            try? FileManager.default.removeItem(at: localURL)
        }

        states[episode.streamUrl] = .idle
        removePersistedEpisode(episode)
    }

    func localURL(for episode: Episode) -> URL? {
        if case .downloaded(let url) = state(for: episode) {
            return url
        }
        return nil
    }

    // MARK: - File management

    nonisolated private func safeFileName(for episode: Episode) -> String {
        let allowed = CharacterSet.alphanumerics
        let safe = episode.streamUrl
            .unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "_" }
            .map(String.init)
            .joined()
        return String(safe.prefix(100))
    }

    private func fileURL(for episode: Episode) -> URL {
        downloadsDirectory.appendingPathComponent("\(safeFileName(for: episode)).mp3")
    }

    /// Pure file operation, safe to run on URLSession's background queue.
    nonisolated private static func moveFile(from tempURL: URL, to destination: URL) throws -> URL {
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }

        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }

    // MARK: - Persistencia de metadata

    private func persistEpisode(_ episode: Episode) {
        var episodes = loadEpisodeMetadata()
        if !episodes.contains(where: { $0.streamUrl == episode.streamUrl }) {
            episodes.append(episode)
        }
        saveEpisodeMetadata(episodes)
        downloadedEpisodes = episodes
    }

    private func removePersistedEpisode(_ episode: Episode) {
        var episodes = loadEpisodeMetadata()
        episodes.removeAll { $0.streamUrl == episode.streamUrl }
        saveEpisodeMetadata(episodes)
        downloadedEpisodes = episodes
        print("Remove episode: \(episode.streamUrl)")
    }

    func loadPersistedEpisodes() {
        let episodes = loadEpisodeMetadata()
        downloadedEpisodes = episodes

        for episode in episodes {
            let url = fileURL(for: episode)

            if FileManager.default.fileExists(atPath: url.path) {
                states[episode.streamUrl] = .downloaded(localURL: url)
            }
        }
    }

    private func loadEpisodeMetadata() -> [Episode] {
        guard let data = userDefaults.data(forKey: episodesKey),
              let episodes = try? JSONDecoder().decode([Episode].self, from: data) else {
            return []
        }
        print("Load metadata: \(episodes.count)")
        return episodes
    }

    private func saveEpisodeMetadata(_ episodes: [Episode]) {
        guard let data = try? JSONEncoder().encode(episodes) else { return }
        userDefaults.set(data, forKey: episodesKey)
        print("Save metadata: \(episodes.count)")
    }
}
