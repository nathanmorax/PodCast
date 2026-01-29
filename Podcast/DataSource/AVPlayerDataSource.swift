//
//  AVPlayerDataSource.swift
//  Podcast
//
//  Created by Jesus Mora on 28/01/26.
//
import UIKit
import AVFoundation

protocol PlayerDataSource {
    
    var onTimeUpdate: ((CMTime, CMTime?) -> Void)? { get set }
    var onStateChange: ((Bool) -> Void)? { get set }
    var onEpisodeStarted: (() -> Void)? { get set }

    
    func play(url: URL)
    func pause()
    func seek(by seconds: Int64)
    func seek(to percentage: Float)
    func setVolume(_ value: Float)
}


class AVPlayerDataSource: PlayerDataSource {
    
    let player: AVPlayer = {
        let avPlayer = AVPlayer()
        avPlayer.automaticallyWaitsToMinimizeStalling = false
        return avPlayer
    }()
    
    init() {
        observeTime()
    }
    
    var onTimeUpdate: ((CMTime, CMTime?) -> Void)?
    var onStateChange: ((Bool) -> Void)?
    var onEpisodeStarted: (() -> Void)? 
    
    
    private func observeTime() {
        let interval = CMTimeMake(value: 1, timescale: 2)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            let duration = self?.player.currentItem?.duration
            self?.onTimeUpdate?(time, duration)
        }
    }
    
    func play(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        player.play()
        onStateChange?(true)
    }
    
    
    func pause() {
        player.pause()
        onStateChange?(false)
    }
    
    func seek(by seconds: Int64) {
        let delta = CMTimeMake(value: seconds, timescale: 1)
        let newTime = CMTimeAdd(player.currentTime(), delta)
        player.seek(to: newTime)
    }
    
    func seek(to percentage: Float) {
        guard let duration = player.currentItem?.duration else { return }
        let seconds = CMTimeGetSeconds(duration) * Double(percentage)
        let time = CMTimeMakeWithSeconds(seconds, preferredTimescale: 600)
        player.seek(to: time)
    }
    
    func setVolume(_ value: Float) {
        player.volume = value
    }
}


class AVPlayerViewModel {
    
    private let player: AVPlayerDataSource
    private var currentURL: URL?
    
    var onTimeUpdate: ((String, String?, Float) -> Void)?
    var onPlayStateChange: ((Bool) -> Void)?
    var onEpisodeStarted: (() -> Void)?

    var isPlaying = false
    
    init(player: AVPlayerDataSource = AVPlayerDataSource()) {
        self.player = player
        bind()
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
        : player.play(url: url)
    }
    
}
