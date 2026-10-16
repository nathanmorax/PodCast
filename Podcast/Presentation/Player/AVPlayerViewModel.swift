//
//  AVPlayerViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 30/01/26.
//

import AVKit
import Observation
import Speech



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
    @ObservationIgnored private let player: AVPlayerDataSource
    @ObservationIgnored private var currentURL: URL?
    @ObservationIgnored private var currentDurationSeconds: Double = 0

    var currentPlaybackSeconds: Double {
        Double(progress) * currentDurationSeconds
    }

    // MARK: - Init
    init(player: AVPlayerDataSource = AVPlayerDataSource()) {
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
            progress = Float(current / total)
            remainingTimeText = Self.shortTime(max(total - current, 0))
        }
        player.onStateChange = { [weak self] in self?.isPlaying = $0 }
        player.onEpisodeStarted = { [weak self] in }
    }

    /// "43:20" under an hour, "1:02:05" above.
    static func shortTime(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    // MARK: - Playback API
    func playEpisode(url: URL) {
        currentURL = url
        player.play(url: url)
    }

    func togglePlayPause() {
        guard currentURL != nil else { return }
        isPlaying ? player.pause() : player.resume()
    }

    func seekForward()  { player.seek(by: 15)  }
    func seekBackward() { player.seek(by: -15) }
    func seek(to percentage: Float) { player.seek(to: percentage) }
    func setVolume(_ value: Float)  { player.setVolume(value) }
}
