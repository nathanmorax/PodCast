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
        guard case .idle = state(for: episode),
              let url = URL(string: episode.streamUrl) else { return }

        states[episode.streamUrl] = .downloading(progress: 0)

        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, error in
            guard let self else { return }

            if let error {
                DispatchQueue.main.async {
                    self.states[episode.streamUrl] = .failed(error.localizedDescription)
                }
                return
            }

            guard let tempURL else { return }

            do {
                let localURL = try self.moveToDocuments(tempURL: tempURL, episode: episode)
                DispatchQueue.main.async {
                    self.states[episode.streamUrl] = .downloaded(localURL: localURL)
                    self.persistEpisode(episode)
                    print("Success Episode: \(episode.title)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.states[episode.streamUrl] = .failed(error.localizedDescription)
                    print("Error Download Episode: \(error.localizedDescription)")
                }
            }
        }

        let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.states[episode.streamUrl] = .downloading(progress: progress.fractionCompleted)
            }
        }
        objc_setAssociatedObject(task, "observation", observation, .OBJC_ASSOCIATION_RETAIN)

        activeTasks[episode.streamUrl] = task
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

    private func safeFileName(for episode: Episode) -> String {
        let allowed = CharacterSet.alphanumerics
        let safe = episode.streamUrl
            .unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "_" }
            .map(String.init)
            .joined()
        // limita a 100 chars para evitar paths demasiado largos
        return String(safe.prefix(100))
    }

    private func moveToDocuments(tempURL: URL, episode: Episode) throws -> URL {
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
