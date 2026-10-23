//
//  SystemNowPlayingService.swift
//  Podcast
//

import UIKit
import MediaPlayer

/// NowPlayingService on the real system: MPNowPlayingInfoCenter for what the
/// lock screen shows, MPRemoteCommandCenter for its buttons and the
/// AirPods'.
///
/// The elapsed time is sent only when something changes (play, pause, seek,
/// a new episode). In between, the system moves the bar by itself from the
/// playback rate, so there's no need to update it twice a second.
@MainActor
final class SystemNowPlayingService: NowPlayingService {

    /// The same jump as the player's own buttons.
    static let skipInterval: Double = 15

    var onCommand: ((RemoteCommand) -> Bool)?

    private let infoCenter: MPNowPlayingInfoCenter
    private let commandCenter: MPRemoteCommandCenter
    private let session: URLSession

    /// The artwork already sent, so it's downloaded once per episode.
    private var artworkURL: URL?
    private var artwork: MPMediaItemArtwork?
    private var artworkTask: Task<Void, Never>?

    init(
        infoCenter: MPNowPlayingInfoCenter = .default(),
        commandCenter: MPRemoteCommandCenter = .shared(),
        session: URLSession = .shared
    ) {
        self.infoCenter = infoCenter
        self.commandCenter = commandCenter
        self.session = session
        registerCommands()
    }

    // MARK: - Info

    func update(_ state: NowPlayingState) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: state.title,
            MPMediaItemPropertyArtist: state.subtitle,
            MPMediaItemPropertyAlbumTitle: state.subtitle,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: state.elapsedSeconds,
            MPNowPlayingInfoPropertyPlaybackRate: state.isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0
        ]
        if state.durationSeconds > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = state.durationSeconds
        }
        if state.artworkURL == artworkURL, let artwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        // On iOS the play/pause state is read from the playback rate above
        // (`playbackState` is macOS only).
        infoCenter.nowPlayingInfo = info

        // The seek bar on the lock screen only works once the length is known.
        commandCenter.changePlaybackPositionCommand.isEnabled = state.durationSeconds > 0

        loadArtworkIfNeeded(state.artworkURL)
    }

    func clear() {
        artworkTask?.cancel()
        artworkURL = nil
        artwork = nil
        infoCenter.nowPlayingInfo = nil
    }

    // MARK: - Artwork

    private func loadArtworkIfNeeded(_ url: URL?) {
        guard url != artworkURL else { return }
        artworkTask?.cancel()
        artworkURL = url
        artwork = nil
        guard let url else { return }

        artworkTask = Task { [weak self, session] in
            let image: UIImage?
            if let cached = ImageMemoryCache.shared.image(for: url) {
                image = cached
            } else if let (data, _) = try? await session.data(from: url) {
                image = await UIImage.decode(from: data)
                if let image { ImageMemoryCache.shared.insert(image, for: url) }
            } else {
                image = nil
            }
            guard let self, let image, !Task.isCancelled, self.artworkURL == url else { return }
            self.attach(image)
        }
    }

    /// Adds the artwork to what's already showing, without touching the rest.
    private func attach(_ image: UIImage) {
        // The handler can be called off the main thread: it only returns the
        // image it captured.
        let artwork = MPMediaItemArtwork(boundsSize: image.size) { @Sendable _ in image }
        self.artwork = artwork
        guard var info = infoCenter.nowPlayingInfo else { return }
        info[MPMediaItemPropertyArtwork] = artwork
        infoCenter.nowPlayingInfo = info
    }

    // MARK: - Commands

    private func registerCommands() {
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.send(.play) ?? .commandFailed
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.send(.pause) ?? .commandFailed
        }
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.send(.togglePlayPause) ?? .commandFailed
        }

        // ⟲ 15 / ⟳ 15 on the lock screen and in Control Center.
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: Self.skipInterval)]
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: Self.skipInterval)]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.send(.skipForward) ?? .commandFailed
        }
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.send(.skipBackward) ?? .commandFailed
        }

        // AirPods and headphones send "next / previous track" (double and
        // triple press). In a podcast that means jumping, like Apple Podcasts.
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.send(.skipForward) ?? .commandFailed
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.send(.skipBackward) ?? .commandFailed
        }

        commandCenter.changePlaybackPositionCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            return self?.send(.seek(toSeconds: event.positionTime)) ?? .commandFailed
        }
    }

    /// The command center calls its handlers on the main thread.
    nonisolated private func send(_ command: RemoteCommand) -> MPRemoteCommandHandlerStatus {
        MainActor.assumeIsolated {
            (onCommand?(command) ?? false) ? .success : .noActionableNowPlayingItem
        }
    }
}
