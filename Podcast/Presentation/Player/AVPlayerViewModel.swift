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
    /// Playback speed (1 = normal), remembered between launches.
    private(set) var playbackRate: Float = 1

    /// The speeds offered under 1×.
    static let rates: [Float] = [0.8, 1, 1.2, 1.5, 1.75, 2]
    private static let rateKey = "player.playbackRate"

    // MARK: - Private
    @ObservationIgnored private let player: PlayerDataSource
    @ObservationIgnored private var currentURL: URL?
    @ObservationIgnored private var currentDurationSeconds: Double = 0
    /// Where the last seek is going. Until the player gets there, the time
    /// observer still reports the old position; ignoring it keeps the bar
    /// from jumping back for a moment after letting go.
    @ObservationIgnored private var pendingSeek: (target: Float, until: Date)?

    /// How long the bar trusts a seek before going back to what the player
    /// says. Resuming waits longer: the stream has to load first.
    private static let seekPatience: TimeInterval = 2
    private static let resumePatience: TimeInterval = 20

    var currentPlaybackSeconds: Double {
        Double(progress) * currentDurationSeconds
    }

    /// The episode's length, once the player knows it (0 before).
    var durationSeconds: Double { currentDurationSeconds }

    /// Called when what the lock screen shows must change: play/pause, a
    /// seek, or the length becoming known. Not on every time tick: the
    /// system moves its bar by itself.
    @ObservationIgnored var onPlaybackChange: (() -> Void)?

    // MARK: - Init
    init(player: PlayerDataSource = AVPlayerDataSource()) {
        self.player = player
        self.bind()
        self.configureAudioSession()
        let saved = UserDefaults.standard.float(forKey: Self.rateKey)
        if Self.rates.contains(saved), saved != 1 {
            playbackRate = saved
            player.setRate(saved)
        }
    }

    // MARK: - Audio session
    /// The category is quick to set; activating the session can block for a
    /// moment (the system warned: "can lead to UI unresponsiveness if called
    /// on the main thread"), so that part runs off the main thread.
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        } catch {
            print("Audio session error:", error)
        }
        Task.detached(priority: .userInitiated) {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Audio session error:", error)
            }
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

            let lengthIsNew = currentDurationSeconds != total
            currentDurationSeconds = total
            let reported = Float(current / total)
            if let seek = pendingSeek {
                let arrived = abs(reported - seek.target) < 0.01
                guard arrived || Date() > seek.until else {
                    // Still going there: keep showing the target (a resumed
                    // episode shows where it was left, never 0:00).
                    remainingTimeText = Self.shortTime(max(total * Double(1 - seek.target), 0))
                    if lengthIsNew { onPlaybackChange?() }
                    return
                }
                pendingSeek = nil
            }
            progress = reported
            remainingTimeText = Self.shortTime(max(total - current, 0))
            // The lock screen learns the length (and where it is) once.
            if lengthIsNew { onPlaybackChange?() }
        }
        player.onStateChange = { [weak self] in
            self?.isPlaying = $0
            self?.onPlaybackChange?()
        }
        player.onEpisodeStarted = {}
    }

    /// "43:20" under an hour, "1:02:05" above.
    nonisolated static func shortTime(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    // MARK: - Playback API
    /// - Parameter progress: 0...1 to resume from (nil or 0 = the beginning).
    func playEpisode(url: URL, startingAt progress: Float? = nil) {
        currentURL = url
        // Unknown until the new episode reports it (the lock screen waits for it).
        currentDurationSeconds = 0
        let start = (progress ?? 0) > 0 ? progress : nil
        // The bar starts where the episode will (not the previous episode's
        // position, and not 0:00 while a resume loads).
        self.progress = start ?? 0
        pendingSeek = start.map { ($0, Date().addingTimeInterval(Self.resumePatience)) }
        remainingTimeText = ""
        // The player starts there itself, silent until it arrives.
        player.play(url: url, startingAt: start)
    }

    /// Stops for good: pauses and gives the audio session back to the system
    /// (other apps' audio can resume).
    func stop() {
        player.pause()
        Task.detached(priority: .utility) {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    func togglePlayPause() {
        guard currentURL != nil else { return }
        isPlaying ? player.pause() : player.resume()
    }

    func seekForward()  { seek(bySeconds: 15) }
    func seekBackward() { seek(bySeconds: -15) }
    /// The full player's ⟳ 30.
    func skipForward30() { seek(bySeconds: 30) }

    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        player.setRate(rate)
        UserDefaults.standard.set(rate, forKey: Self.rateKey)
        onPlaybackChange?()
    }

    /// "1×", "1.5×", "0.8×".
    static func rateText(_ rate: Float) -> String {
        rate.formatted(.number.precision(.fractionLength(0...2))) + "×"
    }

    /// Jumps from where it is now (the 15 s buttons, the lock screen's, the
    /// AirPods'). With the length known it goes through `seek(to:)`, so the
    /// bar moves at once and the lock screen hears about it.
    private func seek(bySeconds delta: Double) {
        guard currentDurationSeconds > 0 else {
            player.seek(by: Int64(delta))
            return
        }
        seek(toSeconds: min(max(currentPlaybackSeconds + delta, 0), currentDurationSeconds))
    }
    /// Jumps there now in the UI (no waiting for the stream), then seeks.
    func seek(to percentage: Float) {
        let target = min(max(percentage, 0), 1)
        progress = target
        pendingSeek = (target, Date().addingTimeInterval(Self.seekPatience))
        player.seek(to: target)
        onPlaybackChange?()
    }

    /// Jumps to a second of the episode (a chapter, a transcript line).
    func seek(toSeconds seconds: Double) {
        guard currentDurationSeconds > 0 else { return }
        seek(to: Float(seconds / currentDurationSeconds))
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
