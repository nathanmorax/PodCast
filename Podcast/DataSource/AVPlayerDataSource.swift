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
    func resume()
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
    
    func resume() {
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
