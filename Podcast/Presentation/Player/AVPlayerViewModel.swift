//
//  AVPlayerViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 30/01/26.
//

import AVKit
import Observation
import Speech



/// Playback state shown by the player and the mini player: main actor.
@MainActor
@Observable
class AVPlayerViewModel {

    // MARK: - Playback state
    var isPlaying: Bool = false
    var currentTimeText: String = "00:00"
    var durationText: String = "00:00"
    /// Time left, shown big in the player's top-right corner ("43:20").
    var remainingTimeText: String = ""
    var progress: Float = 0

    // MARK: - Private
    @ObservationIgnored private let player: PlayerDataSource
    @ObservationIgnored private var currentURL: URL?
    @ObservationIgnored private var currentDurationSeconds: Double = 0
    /// Where the last seek is going. Until the player gets there, the time
    /// observer still reports the old position; ignoring it keeps the bar
    /// from jumping back for a moment after letting go.
    @ObservationIgnored private var pendingSeek: (target: Float, startedAt: Date)?

    var currentPlaybackSeconds: Double {
        Double(progress) * currentDurationSeconds
    }

    // MARK: - Init
    init(player: PlayerDataSource = AVPlayerDataSource()) {
        self.player = player
        self.bind()
        self.configureAudioSession()
    }

    // MARK: - Audio session
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Audio session error:", error)
        }
    }

    // MARK: - Bindings
    private func bind() {
        player.onTimeUpdate = { [weak self] current, duration in
            guard let self else { return }
            currentTimeText = current.toDisplayString()
            durationText = duration?.toDisplayString() ?? ""

            let total = CMTimeGetSeconds(duration ?? CMTime(value: 1, timescale: 1))
            let current = CMTimeGetSeconds(current)
            guard total.isFinite, total > 0, current.isFinite else { return }

            currentDurationSeconds = total
            let reported = Float(current / total)
            if let seek = pendingSeek {
                let arrived = abs(reported - seek.target) < 0.01
                let gaveUp = Date().timeIntervalSince(seek.startedAt) > 2
                guard arrived || gaveUp else { return }
                pendingSeek = nil
            }
            progress = reported
            remainingTimeText = Self.shortTime(max(total - current, 0))
        }
        player.onStateChange = { [weak self] in self?.isPlaying = $0 }
        player.onEpisodeStarted = { [weak self] in }
    }

    /// "43:20" under an hour, "1:02:05" above.
    nonisolated static func shortTime(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    // MARK: - Playback API
    func playEpisode(url: URL) {
        currentURL = url
        player.play(url: url)
    }

    /// Stops for good: pauses and gives the audio session back to the system
    /// (other apps' audio can resume).
    func stop() {
        player.pause()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func togglePlayPause() {
        guard currentURL != nil else { return }
        isPlaying ? player.pause() : player.resume()
    }

    func seekForward()  { player.seek(by: 15)  }
    func seekBackward() { player.seek(by: -15) }
    /// Jumps there now in the UI (no waiting for the stream), then seeks.
    func seek(to percentage: Float) {
        let target = min(max(percentage, 0), 1)
        progress = target
        pendingSeek = (target, Date())
        player.seek(to: target)
    }

    /// "12:04" for a point of the episode, while the finger scrubs.
    func timeText(at percentage: Float) -> String {
        Self.shortTime(Double(percentage) * currentDurationSeconds)
    }

    /// Time left from a point of the episode, while the finger scrubs.
    func remainingText(at percentage: Float) -> String {
        Self.shortTime(max(currentDurationSeconds * (1 - Double(percentage)), 0))
    }
    func setVolume(_ value: Float)  { player.setVolume(value) }
}
