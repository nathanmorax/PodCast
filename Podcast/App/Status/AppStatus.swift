//
//  AppStatus.swift
//  Podcast
//

import Foundation

/// What the status pill at the top says: one word, and a ring that fills
/// when there's progress.
enum AppStatus: Equatable {
    /// Downloads in progress: their average progress (0…1) and how many.
    case downloading(progress: Double, count: Int)
    /// Reading the followed podcasts' feeds.
    case updating
    /// No internet.
    case offline
    /// A download just finished (shown for a moment).
    case downloaded
    /// A download just failed (shown for a moment).
    case failed
}

/// Pure: which status wins when several things happen at once. Problems
/// first (offline, a failure), then what's in progress, then good news.
enum AppStatusResolver {

    static func resolve(isOffline: Bool,
                        downloads: [Double],
                        isUpdating: Bool,
                        flash: AppStatus?) -> AppStatus? {
        if isOffline { return .offline }
        if flash == .failed { return .failed }
        if !downloads.isEmpty {
            let average = downloads.reduce(0, +) / Double(downloads.count)
            return .downloading(progress: average, count: downloads.count)
        }
        if flash == .downloaded { return .downloaded }
        if isUpdating { return .updating }
        return nil
    }

    /// The progress of every download in flight (waiting ones count as 0).
    static func downloadProgress(_ states: [DownloadState]) -> [Double] {
        states.compactMap { state in
            switch state {
            case .waiting: 0
            case .downloading(let progress): progress
            default: nil
            }
        }
    }
}
