//
//  BarCompactionRuleTests.swift
//  PodcastTests
//

import Testing
import CoreGraphics
@testable import Podcast

struct BarCompactionRuleTests {

    /// Feeds offsets one by one, as the user scrolls, and returns the final state.
    private func scroll(_ offsets: [CGFloat], startingAt start: CGFloat = 0, compact: Bool = false, user: Bool = true) -> Bool {
        var rule = BarCompactionRule()
        rule.reset(at: start)
        var isCompact = compact
        for y in offsets {
            isCompact = rule.update(offset: y, isUserScrolling: user, isCompact: isCompact)
        }
        return isCompact
    }

    @Test("Scrolling down past the threshold folds the bar")
    func foldsOnScrollDown() {
        #expect(scroll([40, 80, 120]))
    }

    @Test("Small movements don't change it")
    func ignoresJitter() {
        #expect(!scroll([30, 50, 60], startingAt: 30))
        #expect(scroll([200, 190, 180], startingAt: 200, compact: true))
    }

    @Test("Scrolling back up past the threshold unfolds it")
    func unfoldsOnScrollUp() {
        #expect(!scroll([400, 380, 340], startingAt: 300, compact: true))
    }

    @Test("Near the top it's always unfolded")
    func topAlwaysUnfolded() {
        #expect(!scroll([10], startingAt: 100, compact: true))
    }

    @Test("Offsets that aren't the user's finger never change it")
    func ignoresProgrammaticScroll() {
        #expect(!scroll([300, 600], user: false))
        #expect(scroll([0], startingAt: 500, compact: true, user: false))
    }

    @Test("Direction is measured from the furthest point, not the start")
    func anchorFollowsTheFinger() {
        // Down to 500 (folds), then back up 30: still under the threshold.
        #expect(scroll([100, 300, 500, 470]))
        // Back up 50 from the furthest point: unfolds.
        #expect(!scroll([100, 300, 500, 450]))
    }
}
