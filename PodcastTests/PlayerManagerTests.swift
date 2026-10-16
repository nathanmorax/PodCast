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
}
