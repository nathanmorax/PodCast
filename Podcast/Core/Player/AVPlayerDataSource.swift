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

    /// A seek asked for before the episode could take it (resuming where it
    /// was left, right after loading). Done as soon as the item is ready:
    /// a seek sent earlier is dropped and the episode would start at 0:00.
    private var pendingSeekPercentage: Float?
    private var statusObservations: [NSKeyValueObservation] = []
    
    
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
        
        pendingSeekPercentage = nil
        statusObservations = []
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
        guard let item = player.currentItem else { return }
        guard AVPlayerDataSource.isSeekable(item) else {
            pendingSeekPercentage = percentage
            waitUntilSeekable(item)
            return
        }
        performSeek(to: percentage, in: item)
    }

    private func performSeek(to percentage: Float, in item: AVPlayerItem) {
        let seconds = CMTimeGetSeconds(item.duration) * Double(percentage)
        let time = CMTimeMakeWithSeconds(seconds, preferredTimescale: 600)
        player.seek(to: time)
    }

    private static func isSeekable(_ item: AVPlayerItem) -> Bool {
        item.status == .readyToPlay && item.duration.isNumeric
    }

    /// Runs the pending seek once the item is ready and knows its length
    /// (either can come last, so both are watched).
    private func waitUntilSeekable(_ item: AVPlayerItem) {
        guard statusObservations.isEmpty else { return }
        let waitedFor = ObjectIdentifier(item)
        // KVO can call from any thread: hop to the main actor and look at the
        // player's own item there (the item itself isn't Sendable).
        let check: @Sendable () -> Void = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, let item = self.player.currentItem,
                      ObjectIdentifier(item) == waitedFor, AVPlayerDataSource.isSeekable(item) else { return }
                self.statusObservations = []
                if let percentage = self.pendingSeekPercentage {
                    self.pendingSeekPercentage = nil
                    self.performSeek(to: percentage, in: item)
                }
            }
        }
        statusObservations = [
            item.observe(\.status, options: [.new]) { _, _ in check() },
            item.observe(\.duration, options: [.new]) { _, _ in check() }
        ]
        // It may have become seekable between the check and the observers.
        check()
    }

    func setVolume(_ value: Float) {
        player.volume = value
    }
}
