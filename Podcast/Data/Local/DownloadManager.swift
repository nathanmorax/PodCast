//
//  DonwloadManager.swift
//  Podcast
//
//  Created by Jonathan Mora on 04/06/26.
//

import Foundation
import Observation

enum DownloadState: Equatable {
    case idle
    case waiting
    case downloading(progress: Double)
    case downloaded(localURL: URL)
    case failed(String)

    var iconName: String {
        switch self {
        case .idle:        return "arrow.down"
        case .waiting:     return "arrow.down"
        case .downloaded:  return "checkmark"
        case .downloading: return "circle.dashed"
        case .failed:      return "arrow.down"
        }
    }
}

@MainActor
@Observable
final class DownloadManager {

    static let shared = DownloadManager()
    private init() {
        loadPersistedEpisodes()
    }

    private(set) var states: [String: DownloadState] = [:]
    var downloadedEpisodes: [Episode] = []

    @ObservationIgnored
    private var activeTasks: [String: URLSessionDownloadTask] = [:]

    @ObservationIgnored
    private let userDefaults = UserDefaults.standard

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
        states[key] = .downloading(progress: 0)

        // This completion handler runs on a URLSession background queue,
        // NOT on the main actor.
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, error in
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
            let result = Result { try self.moveToDocuments(tempURL: tempURL, episode: episode) }

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

        let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
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
        cancelDownload(episode)

        if case .downloaded(let url) = state(for: episode) {
            try? FileManager.default.removeItem(at: url)
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

    nonisolated private func moveToDocuments(tempURL: URL, episode: Episode) throws -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("Downloads", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let destination = folder.appendingPathComponent("\(safeFileName(for: episode)).mp3")

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
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = docs.appendingPathComponent("Downloads/\(safeFileName(for: episode)).mp3")

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
