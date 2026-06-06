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

    // episodeStreamUrl -> estado
    private(set) var states: [String: DownloadState] = [:]

    // episodios descargados (para mostrar en una pantalla de descargas)
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
                    
                    print("Suceess Episode: \(episode.title)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.states[episode.streamUrl] = .failed(error.localizedDescription)
                    
                    print("Error Download Episode: \(error.localizedDescription)")
                }
            }
        }

        // Progreso
        let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.states[episode.streamUrl] = .downloading(progress: progress.fractionCompleted)
            }
        }

        // Guardar observation para no perderla (ARC)
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

    private func moveToDocuments(tempURL: URL, episode: Episode) throws -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("Downloads", isDirectory: true)

        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let safeId = episode.streamUrl
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        let destination = folder.appendingPathComponent("\(safeId).mp3")

        // Si ya existe uno previo lo borra
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

        // Reconstruye estados solo si el archivo sigue existiendo
        for episode in episodes {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let safeId = episode.streamUrl
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: ":", with: "_")
            let url = docs.appendingPathComponent("Downloads/\(safeId).mp3")

            if FileManager.default.fileExists(atPath: url.path) {
                states[episode.streamUrl] = .downloaded(localURL: url)
            }
            // Si el archivo no existe, queda .idle — el usuario puede re-descargar
        }
    }

    private func loadEpisodeMetadata() -> [Episode] {
        guard let data = userDefaults.data(forKey: episodesKey),
              let episodes = try? JSONDecoder().decode([Episode].self, from: data) else {
            return []
        }
        print("Load metadata: \(episodes.count)")
        print("Metadata: \(episodes.first?.streamUrl)")

        
        return episodes
    }

    private func saveEpisodeMetadata(_ episodes: [Episode]) {
        guard let data = try? JSONEncoder().encode(episodes) else { return }
        userDefaults.set(data, forKey: episodesKey)
        
        print("Save metadata: \(episodes.count)")
    }
}
