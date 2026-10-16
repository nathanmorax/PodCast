//
//  AVPlayerDataSource.swift
//  Podcast
//
//  Created by Jesus Mora on 28/01/26.
//
import UIKit
import AVFoundation

@MainActor
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
        // queue: .main → this closure runs on the main thread, so it can
        // safely enter the main actor without hopping.
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                let duration = self?.player.currentItem?.duration
                self?.onTimeUpdate?(time, duration)
            }
        }
    }
    
    func play(url: URL) {
//        let playerItem = AVPlayerItem(url: url)
        
        let playerItem: AVPlayerItem
        
        if url.isFileURL {
            playerItem = AVPlayerItem(url: url)
        } else {
            // Remoto — configura para streaming
            let asset = AVURLAsset(url: url, options: [
                "AVURLAssetHTTPHeaderFieldsKey": ["Range": "bytes=0-"]
            ])
            playerItem = AVPlayerItem(asset: asset)
        }
        
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
