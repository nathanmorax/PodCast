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
    case downloading(progress: Double)
    case downloaded(localURL: URL)
    case failed(String)
}

@Observable
final class DownloadManager {
    static let shared = DownloadManager()
    private init() {}

    // episodeStreamUrl -> estado
    private var states: [String: DownloadState] = [:]

    func state(for episode: Episode) -> DownloadState {
        states[episode.streamUrl] ?? .idle
    }

    func download(_ episode: Episode) {
        guard let url = URL(string: episode.streamUrl) else { return }
        states[episode.streamUrl] = .downloading(progress: 0)

        Task {
            do {
                let localURL = try await AudioDownloader.shared.download(from: url)
                await MainActor.run {
                    states[episode.streamUrl] = .downloaded(localURL: localURL)
                }
            } catch {
                await MainActor.run {
                    states[episode.streamUrl] = .failed(error.localizedDescription)
                }
            }
        }
    }

    func isDownloaded(_ episode: Episode) -> Bool {
        if case .downloaded = state(for: episode) { return true }
        return false
    }
}
