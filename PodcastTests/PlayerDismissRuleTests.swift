//
//  PlayerDismissRuleTests.swift
//  PodcastTests
//

import Testing
@testable import Podcast

@Suite("PlayerDismissRule")
struct PlayerDismissRuleTests {

    @Test("A short, slow pull springs back")
    func shortPull() {
        #expect(!PlayerDismissRule.shouldClose(translation: 60, predictedEnd: 90))
    }

    @Test("Pulling far enough closes")
    func longPull() {
        #expect(PlayerDismissRule.shouldClose(translation: 200, predictedEnd: 210))
    }

    @Test("A quick flick closes even if it moved little")
    func flick() {
        #expect(PlayerDismissRule.shouldClose(translation: 40, predictedEnd: 600))
    }

    @Test("Pushing up never closes")
    func upward() {
        #expect(!PlayerDismissRule.shouldClose(translation: -30, predictedEnd: 900))
    }
}
