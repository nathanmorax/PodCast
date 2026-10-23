//
//  NowPlayingState.swift
//  Podcast
//

import Foundation

/// What the system shows outside the app (lock screen, Control Center,
/// Dynamic Island, AirPods, CarPlay's Now Playing): the episode, its show and
/// where playback is. A plain value, so it's easy to build and to test.
struct NowPlayingState: Equatable, Sendable {
    let title: String
    /// The line under the title: the show (or author).
    let subtitle: String
    let artworkURL: URL?
    /// 0 while the episode hasn't reported its length yet.
    let durationSeconds: Double
    let elapsedSeconds: Double
    let isPlaying: Bool
}

extension NowPlayingState {
    init(episode: Episode, durationSeconds: Double, elapsedSeconds: Double, isPlaying: Bool) {
        self.init(
            title: episode.title,
            subtitle: episode.author,
            artworkURL: episode.imageUrl.flatMap { $0.hasPrefix("http") ? URL(string: $0) : nil },
            durationSeconds: durationSeconds,
            elapsedSeconds: elapsedSeconds,
            isPlaying: isPlaying
        )
    }
}
