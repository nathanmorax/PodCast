//
//  PlayerManager.swift
//  Podcast
//
//  Created by Jonathan Mora on 23/03/26.
//
import SwiftUI
import Observation

@MainActor
@Observable
final class PlayerManager {
    
    /// The app's player: the only one wired to the lock screen.
    static let shared = PlayerManager(nowPlaying: SystemNowPlayingService())

    @ObservationIgnored
    private let downloadManager: DownloadManager

    @ObservationIgnored
    private let recentlyPlayed: RecentlyPlayedManager

    /// Lock screen, Control Center and AirPods. Nil in tests and previews.
    @ObservationIgnored
    private let nowPlaying: (any NowPlayingService)?

    init(
        downloadManager: DownloadManager = .shared,
        recentlyPlayed: RecentlyPlayedManager = .shared,
        viewModel: AVPlayerViewModel = AVPlayerViewModel(),
        nowPlaying: (any NowPlayingService)? = nil
    ) {
        self.downloadManager = downloadManager
        self.recentlyPlayed = recentlyPlayed
        self.viewModel = viewModel
        self.nowPlaying = nowPlaying
        connectNowPlaying()
    }
    
    var currentEpisode: Episode?
    var presentation: PlayerPresentation = .hidden
    
    let viewModel: AVPlayerViewModel
    let transcript  = TranscriptViewModel()
    
    enum PlayerPresentation {
        case hidden
        case mini
        case expanded
    }
    
    // MARK: - Public API
    
    /// Set when the mini player shows the last episode at launch without its
    /// audio loaded yet: where to resume when the listener presses play.
    @ObservationIgnored private var restoredProgress: Double?

    /// At launch: if something was played before, show the mini player with
    /// it, paused. The audio isn't loaded (no network, no sound) until the
    /// listener presses play; then it resumes where it was left.
    func restoreLastPlayed() {
        guard currentEpisode == nil, let last = recentlyPlayed.items.first else { return }
        // Finished episodes start again from the beginning.
        let progress = last.progress < 0.98 ? last.progress : 0
        currentEpisode = last.episode
        defer { publishNowPlaying() }
        restoredProgress = progress
        viewModel.progress = Float(progress)
        presentation = .mini
    }

    /// - Parameter progress: where to start (0...1) when it's a different
    ///   episode, e.g. resuming one from "Recently played". Nil: the start.
    func play(_ episode: Episode, presentation: PlayerPresentation = .expanded, from progress: Double? = nil) {
        // The episode restored at launch: load it now, from where it was left.
        if let resume = restoredProgress {
            restoredProgress = nil
            if currentEpisode?.streamUrl == episode.streamUrl {
                recentlyPlayed.record(episode)
                startPlayback(of: episode, startingAt: resume)
                withAnimation(AppAnimation.playerPresentation) {
                    self.presentation = presentation
                }
                return
            }
        }

        // Same episode that's already loaded: don't reload it from 0:00.
        // Just make sure it's playing and show the player.
        if currentEpisode?.streamUrl == episode.streamUrl {
            if !viewModel.isPlaying {
                viewModel.togglePlayPause()
            }
            withAnimation(AppAnimation.playerPresentation) {
                self.presentation = presentation
            }
            return
        }
        
        // Save how far the listener got in the episode they're leaving,
        // then put the new one at the top of "recently played".
        if let previous = currentEpisode, previous.streamUrl != episode.streamUrl {
            recentlyPlayed.updateProgress(for: previous, progress: Double(viewModel.progress))
        }
        recentlyPlayed.record(episode)
        
        currentEpisode = episode
        // The lock screen hears about it once playback starts (onPlaybackChange).
        startPlayback(of: episode, startingAt: progress)
        
        withAnimation(AppAnimation.playerPresentation) {
            self.presentation = presentation
        }
    }

    /// Loads the episode's audio (downloaded file if there is one) and plays.
    private func startPlayback(of episode: Episode, startingAt progress: Double?) {
        let url: URL
        if let localURL = downloadManager.localURL(for: episode) {
            url = localURL
        } else {
            guard let remoteURL = URL(string: episode.streamUrl) else { return }
            url = remoteURL
        }

        transcript.reset()
        viewModel.playEpisode(url: url, startingAt: progress.map(Float.init))
        transcript.loadIfCached(for: episode.streamUrl)
    }
    
    func expand() {
        // Repeated taps on the mini player: one opening is enough.
        guard presentation != .expanded else { return }
        withAnimation(AppAnimation.playerPresentation) {
            presentation = .expanded
        }
    }
    
    func collapse() {
        withAnimation(AppAnimation.playerDismiss) {
            presentation = .mini
        }
    }
    
    func playOrToggle(_ episode: Episode, presentation: PlayerPresentation = .mini) {
        if currentEpisode?.streamUrl == episode.streamUrl {
            togglePlayPause()
            return
        }
        
        play(episode, presentation: presentation)
    }
    
    func togglePlayPause() {
        // Restored at launch and never loaded: the first play loads it.
        if restoredProgress != nil, let episode = currentEpisode {
            play(episode, presentation: presentation == .hidden ? .mini : presentation)
            return
        }
        viewModel.togglePlayPause()
    }

    /// The app is being closed (force quit): remember where the listener was
    /// in the current episode, then stop the audio.
    func stopForTermination() {
        if let current = currentEpisode {
            recentlyPlayed.updateProgress(for: current, progress: Double(viewModel.progress))
        }
        viewModel.stop()
        nowPlaying?.clear()
    }
}

// MARK: - Lock screen, Control Center, AirPods

extension PlayerManager {

    /// Listens to the player (play, pause, seek, length known) and to the
    /// controls outside the app.
    private func connectNowPlaying() {
        guard let nowPlaying else { return }
        viewModel.onPlaybackChange = { [weak self] in self?.publishNowPlaying() }
        nowPlaying.onCommand = { [weak self] command in
            self?.handle(command) ?? false
        }
    }

    /// Sends the current episode and position to the lock screen.
    func publishNowPlaying() {
        guard let nowPlaying else { return }
        guard let episode = currentEpisode else {
            nowPlaying.clear()
            return
        }
        // A restored episode isn't loaded yet: its position is the saved one.
        let elapsed = restoredProgress.map { $0 * (episode.durationSeconds ?? 0) }
            ?? viewModel.currentPlaybackSeconds
        nowPlaying.update(NowPlayingState(
            episode: episode,
            durationSeconds: viewModel.durationSeconds > 0 ? viewModel.durationSeconds : (episode.durationSeconds ?? 0),
            elapsedSeconds: elapsed,
            isPlaying: viewModel.isPlaying
        ))
    }

    /// A control pressed outside the app. False when there's nothing to act on.
    @discardableResult
    func handle(_ command: RemoteCommand) -> Bool {
        guard currentEpisode != nil else { return false }
        switch command {
        case .play:
            if !viewModel.isPlaying { togglePlayPause() }
        case .pause:
            if viewModel.isPlaying { togglePlayPause() }
        case .togglePlayPause:
            togglePlayPause()
        case .skipForward:
            guard restoredProgress == nil else { return false }
            viewModel.seekForward()
        case .skipBackward:
            guard restoredProgress == nil else { return false }
            viewModel.seekBackward()
        case .seek(let seconds):
            guard restoredProgress == nil else { return false }
            viewModel.seek(toSeconds: seconds)
        }
        return true
    }
}
