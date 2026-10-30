//
//  SleepTimerTests.swift
//  PodcastTests
//

import Testing
@testable import Podcast

@Suite("SleepTimer")
struct SleepTimerTests {

    @Test("Minutes are minutes")
    func minutes() {
        #expect(SleepTimer.seconds(for: .minutes(15), remaining: 10, rate: 2) == 900)
    }

    @Test("End of episode counts the speed")
    func endOfEpisode() {
        #expect(SleepTimer.seconds(for: .endOfEpisode, remaining: 600, rate: 1) == 600)
        #expect(SleepTimer.seconds(for: .endOfEpisode, remaining: 600, rate: 2) == 300)
    }

    @Test("Rates read like 1× and 1.5×")
    @MainActor
    func rateText() {
        #expect(AVPlayerViewModel.rateText(1).hasPrefix("1"))
        #expect(AVPlayerViewModel.rateText(1.5).contains("5"))
    }
}
