//
//  PlayerManagerTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

@MainActor
struct PlayerManagerTests {

    private let player = FakePlayerDataSource()
    private let recentlyPlayed = RecentlyPlayedManager(userDefaults: .isolated())
    private let sut: PlayerManager

    private let first = Fixtures.episode(streamUrl: "https://example.com/1.mp3", title: "Uno")
    private let second = Fixtures.episode(streamUrl: "https://example.com/2.mp3", title: "Dos")

    init() {
        let downloads = DownloadManager(
            userDefaults: .isolated(),
            downloadsDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("PlayerManagerTests-\(UUID().uuidString)", isDirectory: true)
        )
        sut = PlayerManager(
            downloadManager: downloads,
            recentlyPlayed: recentlyPlayed,
            viewModel: AVPlayerViewModel(player: player)
        )
    }

    @Test("Playing an episode loads it, opens the player and records it")
    func playNewEpisode() {
        sut.play(first)

        #expect(player.playedURLs == [URL(string: first.streamUrl)!])
        #expect(sut.currentEpisode?.streamUrl == first.streamUrl)
        #expect(sut.presentation == .expanded)
        #expect(sut.viewModel.isPlaying)
        #expect(recentlyPlayed.items.map(\.id) == [first.streamUrl])
    }

    @Test("Tapping the episode that's already loaded doesn't restart it from 0:00")
    func sameEpisodeDoesNotRestart() {
        sut.play(first)
        player.sendTime(current: 600, total: 1_800)

        sut.play(first)

        #expect(player.playedURLs.count == 1)
        #expect(sut.viewModel.progress > 0.33)
    }

    @Test("Tapping the loaded episode while paused resumes it")
    func sameEpisodeResumesWhenPaused() {
        sut.play(first)
        sut.togglePlayPause()
        #expect(!sut.viewModel.isPlaying)

        sut.play(first, presentation: .mini)

        #expect(player.playedURLs.count == 1)
        #expect(player.resumeCount == 1)
        #expect(sut.viewModel.isPlaying)
        #expect(sut.presentation == .mini)
    }

    @Test("Switching episodes saves how far you got in the one you leave")
    func switchingSavesProgress() {
        sut.play(first)
        player.sendTime(current: 450, total: 1_000)

        sut.play(second)

        #expect(player.playedURLs.count == 2)
        #expect(recentlyPlayed.items.map(\.id) == [second.streamUrl, first.streamUrl])
        let saved = recentlyPlayed.items.last?.progress ?? 0
        #expect(abs(saved - 0.45) < 0.001)
    }

    @Test("playOrToggle pauses the episode that's playing instead of reloading it")
    func playOrTogglePauses() {
        sut.play(first)

        sut.playOrToggle(first)

        #expect(player.playedURLs.count == 1)
        #expect(player.pauseCount == 1)
        #expect(!sut.viewModel.isPlaying)
    }

    @Test("expand and collapse move between the full and the mini player")
    func presentation() {
        sut.play(first, presentation: .mini)

        sut.expand()
        #expect(sut.presentation == .expanded)

        sut.collapse()
        #expect(sut.presentation == .mini)
    }

    @Test("Closing the app saves the position and stops the audio")
    func stopForTermination() {
        sut.play(first)
        player.sendTime(current: 300, total: 1_000)

        sut.stopForTermination()

        #expect(!sut.viewModel.isPlaying)
        #expect(player.pauseCount == 1)
        let saved = recentlyPlayed.items.first?.progress ?? 0
        #expect(abs(saved - 0.3) < 0.001)
    }

    @Test("At launch the last episode shows in the mini player, paused and not loaded")
    func restoreLastPlayed() {
        recentlyPlayed.record(first)
        recentlyPlayed.updateProgress(for: first, progress: 0.4)

        sut.restoreLastPlayed()

        #expect(sut.currentEpisode?.streamUrl == first.streamUrl)
        #expect(sut.presentation == .mini)
        #expect(abs(sut.viewModel.progress - 0.4) < 0.001)
        #expect(player.playedURLs.isEmpty)
    }

    @Test("Pressing play on the restored episode loads it and resumes where it was")
    func playRestored() {
        recentlyPlayed.record(first)
        recentlyPlayed.updateProgress(for: first, progress: 0.5)
        sut.restoreLastPlayed()

        sut.togglePlayPause()
        #expect(player.playedURLs.count == 1)
        // The player starts there itself.
        #expect(player.startPercentages.last == 0.5)

        // A tick still at 0:00 while it loads doesn't move the bar back.
        player.sendTime(current: 0, total: 1_000)
        #expect(abs(sut.viewModel.progress - 0.5) < 0.001)
    }

    @Test("Nothing played before: no mini player")
    func restoreNothing() {
        sut.restoreLastPlayed()
        #expect(sut.currentEpisode == nil)
        #expect(sut.presentation == .hidden)
    }
}

@MainActor
@Suite("Resume from Recently played")
struct ResumeTests {

    private let player = FakePlayerDataSource()
    private let recentlyPlayed = RecentlyPlayedManager(userDefaults: .isolated())
    private let sut: PlayerManager
    private let episode = Fixtures.episode(streamUrl: "https://example.com/r.mp3", title: "Reanudar")

    init() {
        sut = PlayerManager(
            downloadManager: DownloadManager(
                userDefaults: .isolated(),
                downloadsDirectory: FileManager.default.temporaryDirectory
                    .appendingPathComponent("ResumeTests-\(UUID().uuidString)", isDirectory: true)
            ),
            recentlyPlayed: recentlyPlayed,
            viewModel: AVPlayerViewModel(player: player)
        )
    }

    @Test("Playing from a saved position starts there, not at 0:00")
    func startsWhereLeft() {
        sut.play(episode, from: 0.4)

        // The player itself is told to start at 40% (not to play 0:00 and jump).
        #expect(player.startPercentages.last == 0.4)
        #expect(abs(sut.viewModel.progress - 0.4) < 0.001)

        // A tick still at 0:00 while it loads doesn't move the bar back.
        player.sendTime(current: 0, total: 1_000)
        #expect(abs(sut.viewModel.currentPlaybackSeconds - 400) < 0.5)

        // Once there, it follows the player as usual.
        player.sendTime(current: 401, total: 1_000)
        #expect(abs(sut.viewModel.currentPlaybackSeconds - 401) < 0.5)
    }

    @Test("Pausing saves where the episode is")
    func pauseSaves() {
        sut.play(episode)
        player.sendTime(current: 300, total: 1_000)

        sut.togglePlayPause()

        #expect(abs((recentlyPlayed.items.first?.progress ?? 0) - 0.3) < 0.01)
    }

    @Test("A finished episode starts over")
    func finishedStartsOver() {
        let finished = RecentlyPlayed(episode: episode, lastPlayedAt: .now, progress: 0.99)
        #expect(finished.resumeProgress == 0)
        #expect(RecentlyPlayed(episode: episode, lastPlayedAt: .now, progress: 0.5).resumeProgress == 0.5)
    }
}
