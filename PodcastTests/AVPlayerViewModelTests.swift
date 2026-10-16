//
//  AVPlayerViewModelTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

@MainActor
struct AVPlayerViewModelTests {

    @Test("Short time: m:ss under an hour, h:mm:ss above", arguments: [
        (0.0, "0:00"),
        (59.4, "0:59"),
        (59.6, "1:00"),
        (2_600.0, "43:20"),
        (3_725.0, "1:02:05"),
    ])
    func shortTime(seconds: Double, expected: String) {
        #expect(AVPlayerViewModel.shortTime(seconds) == expected)
    }

    @Test("Time updates fill progress and the remaining time")
    func timeUpdates() {
        let player = FakePlayerDataSource()
        let sut = AVPlayerViewModel(player: player)

        player.sendTime(current: 600, total: 3_200)

        #expect(sut.remainingTimeText == "43:20")
        #expect(abs(sut.progress - 0.1875) < 0.0001)
        #expect(abs(sut.currentPlaybackSeconds - 600) < 0.5)
    }

    @Test("A time update without a valid duration is ignored")
    func invalidDuration() {
        let player = FakePlayerDataSource()
        let sut = AVPlayerViewModel(player: player)

        player.sendTime(current: 10, total: 0)

        #expect(sut.progress == 0)
        #expect(sut.remainingTimeText.isEmpty)
    }

    @Test("Play/pause does nothing until an episode is loaded")
    func toggleWithoutEpisode() {
        let player = FakePlayerDataSource()
        let sut = AVPlayerViewModel(player: player)

        sut.togglePlayPause()

        #expect(player.resumeCount == 0)
        #expect(player.pauseCount == 0)
    }

    @Test("Play/pause alternates once an episode is loaded")
    func toggleAlternates() {
        let player = FakePlayerDataSource()
        let sut = AVPlayerViewModel(player: player)
        sut.playEpisode(url: URL(string: "https://example.com/1.mp3")!)

        sut.togglePlayPause()
        #expect(!sut.isPlaying)

        sut.togglePlayPause()
        #expect(sut.isPlaying)
        #expect(player.pauseCount == 1)
        #expect(player.resumeCount == 1)
    }
}
