//
//  NowPlayingTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

/// Stands in for the lock screen: records what it was asked to show.
@MainActor
final class FakeNowPlayingService: NowPlayingService {
    var onCommand: ((RemoteCommand) -> Bool)?
    private(set) var states: [NowPlayingState] = []
    private(set) var clearCount = 0

    var last: NowPlayingState? { states.last }

    func update(_ state: NowPlayingState) { states.append(state) }
    func clear() { clearCount += 1 }

    /// Simulates a press on the lock screen or the AirPods.
    @discardableResult
    func press(_ command: RemoteCommand) -> Bool {
        onCommand?(command) ?? false
    }
}

@MainActor
@Suite("Now Playing (lock screen, Control Center, AirPods)")
struct NowPlayingTests {

    private let player = FakePlayerDataSource()
    private let nowPlaying = FakeNowPlayingService()
    private let sut: PlayerManager

    private let episode = Fixtures.episode(streamUrl: "https://example.com/1.mp3", title: "Uno")

    init() {
        let downloads = DownloadManager(
            userDefaults: .isolated(),
            downloadsDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("NowPlayingTests-\(UUID().uuidString)", isDirectory: true)
        )
        sut = PlayerManager(
            downloadManager: downloads,
            recentlyPlayed: RecentlyPlayedManager(userDefaults: .isolated()),
            viewModel: AVPlayerViewModel(player: player),
            nowPlaying: nowPlaying
        )
    }

    @Test("Playing an episode shows it on the lock screen, playing")
    func showsEpisode() {
        sut.play(episode)

        #expect(nowPlaying.last?.title == "Uno")
        #expect(nowPlaying.last?.subtitle == episode.author)
        #expect(nowPlaying.last?.isPlaying == true)
    }

    @Test("Pausing in the app updates the lock screen")
    func pauseUpdates() {
        sut.play(episode)
        sut.togglePlayPause()

        #expect(nowPlaying.last?.isPlaying == false)
    }

    @Test("The length and position reach the lock screen once known")
    func lengthAndPosition() {
        sut.play(episode)
        player.sendTime(current: 600, total: 1_800)

        #expect(nowPlaying.last?.durationSeconds == 1_800)
        #expect(abs((nowPlaying.last?.elapsedSeconds ?? 0) - 600) < 0.5)
    }

    @Test("Pause and play from the lock screen")
    func pauseAndPlayCommands() {
        sut.play(episode)

        #expect(nowPlaying.press(.pause))
        #expect(!sut.viewModel.isPlaying)
        #expect(nowPlaying.press(.play))
        #expect(sut.viewModel.isPlaying)
        #expect(player.resumeCount == 1)
    }

    @Test("Play when already playing does nothing (no double toggle)")
    func playWhilePlaying() {
        sut.play(episode)
        nowPlaying.press(.play)

        #expect(sut.viewModel.isPlaying)
        #expect(player.pauseCount == 0)
    }

    @Test("AirPods' double press jumps 15 s forward; triple press, back")
    func skipCommands() {
        sut.play(episode)
        player.sendTime(current: 600, total: 1_800)

        nowPlaying.press(.skipForward)
        #expect(abs(sut.viewModel.currentPlaybackSeconds - 615) < 0.5)

        nowPlaying.press(.skipBackward)
        nowPlaying.press(.skipBackward)
        #expect(abs(sut.viewModel.currentPlaybackSeconds - 585) < 0.5)
    }

    @Test("Dragging the lock screen bar seeks there")
    func seekCommand() {
        sut.play(episode)
        player.sendTime(current: 0, total: 1_800)

        nowPlaying.press(.seek(toSeconds: 900))

        #expect(abs(sut.viewModel.progress - 0.5) < 0.001)
        #expect(abs((nowPlaying.last?.elapsedSeconds ?? 0) - 900) < 0.5)
    }

    @Test("With nothing loaded, the controls report there's nothing to play")
    func nothingLoaded() {
        #expect(!nowPlaying.press(.play))
        #expect(!nowPlaying.press(.skipForward))
    }

    @Test("Closing the app clears the lock screen")
    func terminationClears() {
        sut.play(episode)
        sut.stopForTermination()

        #expect(nowPlaying.clearCount == 1)
    }
}

@MainActor
@Suite("Mini player ⟳ 15")
struct MiniPlayerSkipTests {

    @Test("⟳ 15 jumps 15 s forward once the episode is loaded")
    func skipsForward() {
        let player = FakePlayerDataSource()
        let sut = PlayerManager(
            downloadManager: DownloadManager(
                userDefaults: .isolated(),
                downloadsDirectory: FileManager.default.temporaryDirectory
                    .appendingPathComponent("MiniSkip-\(UUID().uuidString)", isDirectory: true)
            ),
            recentlyPlayed: RecentlyPlayedManager(userDefaults: .isolated()),
            viewModel: AVPlayerViewModel(player: player)
        )
        #expect(!sut.canSkip)

        sut.play(Fixtures.episode())
        player.sendTime(current: 100, total: 1_000)
        #expect(sut.canSkip)

        sut.skipForward()
        #expect(abs(sut.viewModel.currentPlaybackSeconds - 115) < 0.5)
    }
}
