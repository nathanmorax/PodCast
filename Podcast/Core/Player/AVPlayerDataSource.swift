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

    /// A seek the item can't take yet (it isn't ready or doesn't know its
    /// length). It runs as soon as it can: a seek sent earlier is dropped.
    private var pendingSeekPercentage: Float?
    /// The episode waits silent until that seek lands, then plays: resuming
    /// never plays a second of 0:00 first.
    private var playsAfterPendingSeek = false
    private var seekableObservations: [NSKeyValueObservation] = []

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

    // MARK: - Playback

    func play(url: URL, startingAt percentage: Float?) {
        // AVPlayer asks the server for the byte ranges it needs (to start
        // mid-episode or seek). A fixed "Range: bytes=0-" header overrode
        // them and made every jump load from the beginning.
        let playerItem = AVPlayerItem(url: url)

        // A new item keeps the player's rate: stop first so it can't start
        // at 0:00 before jumping to where it was left.
        player.pause()
        pendingSeekPercentage = nil
        playsAfterPendingSeek = false
        seekableObservations = []
        player.replaceCurrentItem(with: playerItem)

        if let percentage, percentage > 0 {
            pendingSeekPercentage = percentage
            playsAfterPendingSeek = true
            waitUntilSeekable(playerItem)
        } else {
            player.play()
        }
        // For the UI it's playing from now (it's loading where it was left).
        onStateChange?(true)
    }

    func resume() {
        if pendingSeekPercentage != nil {
            // Still loading the resume point: play once it lands.
            playsAfterPendingSeek = true
        } else {
            player.play()
        }
        onStateChange?(true)
    }

    func pause() {
        playsAfterPendingSeek = false
        player.pause()
        onStateChange?(false)
    }

    // MARK: - Seeking

    func seek(by seconds: Int64) {
        let delta = CMTimeMake(value: seconds, timescale: 1)
        let newTime = CMTimeAdd(player.currentTime(), delta)
        player.seek(to: newTime)
    }

    func seek(to percentage: Float) {
        guard let item = player.currentItem else { return }
        guard pendingSeekPercentage == nil, AVPlayerDataSource.isSeekable(item) else {
            // Not ready yet (or still waiting for the resume point): the
            // latest target wins, it runs once the item can take it.
            pendingSeekPercentage = percentage
            waitUntilSeekable(item)
            return
        }
        performSeek(to: percentage, in: item, thenPlay: false)
    }

    private func performSeek(to percentage: Float, in item: AVPlayerItem, thenPlay: Bool) {
        let seconds = CMTimeGetSeconds(item.duration) * Double(percentage)
        let time = CMTimeMakeWithSeconds(seconds, preferredTimescale: 600)
        guard thenPlay else {
            player.seek(to: time)
            return
        }
        // Exact, then play: the first thing heard is where it was left.
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.player.currentItem.map(ObjectIdentifier.init) == ObjectIdentifier(item) as ObjectIdentifier? else { return }
                // Paused meanwhile: stay paused at the resume point.
                if self.playsAfterPendingSeek {
                    self.playsAfterPendingSeek = false
                    self.player.play()
                }
            }
        }
    }

    private static func isSeekable(_ item: AVPlayerItem) -> Bool {
        item.status == .readyToPlay && item.duration.isNumeric
    }

    /// Runs the pending seek once the item is ready and knows its length
    /// (either can come last, so both are watched).
    private func waitUntilSeekable(_ item: AVPlayerItem) {
        guard seekableObservations.isEmpty else { return }
        let waitedFor = ObjectIdentifier(item)
        // KVO can call from any thread: hop to the main actor and look at the
        // player's own item there (the item itself isn't Sendable).
        let check: @Sendable () -> Void = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, let item = self.player.currentItem,
                      ObjectIdentifier(item) == waitedFor,
                      AVPlayerDataSource.isSeekable(item),
                      let percentage = self.pendingSeekPercentage else { return }
                self.seekableObservations = []
                self.pendingSeekPercentage = nil
                self.performSeek(to: percentage, in: item, thenPlay: self.playsAfterPendingSeek)
            }
        }
        seekableObservations = [
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
