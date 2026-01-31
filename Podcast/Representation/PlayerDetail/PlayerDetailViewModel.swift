//
//  PlayerDetailViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 30/01/26.
//
import AVKit

class AVPlayerViewModel {
    
    private let player: AVPlayerDataSource
    private var currentURL: URL?
    
    var onTimeUpdate: ((String, String?, Float) -> Void)?
    var onPlayStateChange: ((Bool) -> Void)?
    var onEpisodeStarted: (() -> Void)?

    var isPlaying = false
    
    init(player: AVPlayerDataSource = AVPlayerDataSource()) {
        self.player = player
        self.bind()
        self.configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Audio session error:", error)
        }
    }
    
    private func bind() {
        player.onTimeUpdate = { [weak self] current, duration in
            let currentText = current.toDisplayString()
            let durationText = duration?.toDisplayString()
            let percentage = Float(
                CMTimeGetSeconds(current) /
                CMTimeGetSeconds(duration ?? CMTime(value: 1, timescale: 1))
            )
            self?.onTimeUpdate?(currentText, durationText, percentage)
        }
        
        player.onStateChange = { [weak self] isPlaying in
            self?.isPlaying = isPlaying
            self?.onPlayStateChange?(isPlaying)
        }
        
        player.onEpisodeStarted = { [weak self] in
            self?.onEpisodeStarted?()
        }
    }
    
    
    func playEpisode(_ episode: Episode) {
        guard let url = URL(string: episode.streamUrl ?? "") else { return }
        currentURL = url
        player.play(url: url)
    }
    
    func seekForward() {
        player.seek(by: 15)
    }
    
    func seekBackward() {
        player.seek(by: -15)
    }
    
    func seek(to percentage: Float) {
        player.seek(to: percentage)
    }
    
    func setVolume(_ value: Float) {
        player.setVolume(value)
    }
    
    func togglePlayPause() {
        guard let url = currentURL else { return }
        
        isPlaying
        ? player.pause()
        : player.resume()
    }
}
