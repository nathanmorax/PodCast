//
//  Fakes.swift
//  PodcastTests
//

import UIKit
import AVFoundation
@testable import Podcast

// MARK: - Player

/// Records what the view model asks the player to do. No audio, no network.
@MainActor
final class FakePlayerDataSource: PlayerDataSource {
    var onTimeUpdate: ((CMTime, CMTime?) -> Void)?
    var onStateChange: ((Bool) -> Void)?
    var onEpisodeStarted: (() -> Void)?

    private(set) var playedURLs: [URL] = []
    /// The start each play asked for (nil = the beginning).
    private(set) var startPercentages: [Float?] = []
    private(set) var resumeCount = 0
    private(set) var pauseCount = 0

    // Like AVPlayerDataSource, report the new state through the callback.
    func play(url: URL, startingAt percentage: Float?) {
        playedURLs.append(url)
        startPercentages.append(percentage)
        onStateChange?(true)
    }

    func resume() {
        resumeCount += 1
        onStateChange?(true)
    }

    func pause() {
        pauseCount += 1
        onStateChange?(false)
    }

    func seek(by seconds: Int64) {}
    func seek(to percentage: Float) {}
    func setVolume(_ value: Float) {}

    /// Simulates the periodic time observer.
    func sendTime(current: Double, total: Double) {
        onTimeUpdate?(
            CMTime(seconds: current, preferredTimescale: 600),
            CMTime(seconds: total, preferredTimescale: 600)
        )
    }
}

// MARK: - Navigation

/// Stands in for MainContainerController: plain stacks, records what it's asked.
@MainActor
final class FakeNavigationContainer: NavigationContainer {
    let stacks: [AppTab: UINavigationController]
    let searchStack = UINavigationController(rootViewController: UIViewController())

    private(set) var shownTabs: [AppTab] = []
    private(set) var showSearchCount = 0
    private(set) var focusSearchCount = 0

    init() {
        var stacks: [AppTab: UINavigationController] = [:]
        for tab in AppTab.allCases {
            stacks[tab] = UINavigationController(rootViewController: UIViewController())
        }
        self.stacks = stacks
    }

    func stack(for tab: AppTab) -> UINavigationController? { stacks[tab] }
    func show(_ tab: AppTab) { shownTabs.append(tab) }
    func showSearch() { showSearchCount += 1 }
    func focusSearch() { focusSearchCount += 1 }
}
