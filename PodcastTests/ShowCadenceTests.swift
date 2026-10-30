//
//  ShowCadenceTests.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

@Suite("ShowCadence")
struct ShowCadenceTests {

    private let day: TimeInterval = 86_400
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func dates(every gap: Double, count: Int) -> [Date] {
        (0..<count).map { now.addingTimeInterval(-Double($0) * gap * day) }
    }

    @Test("Reads the rhythm from the gaps", arguments: [
        (1.0, ShowCadence.daily),
        (7.0, .weekly),
        (14.0, .biweekly),
        (30.0, .monthly)
    ])
    func cadence(gap: Double, expected: ShowCadence) {
        #expect(ShowCadence(dates: dates(every: gap, count: 6)) == expected)
    }

    @Test("No rhythm with fewer than three episodes")
    func tooFew() {
        #expect(ShowCadence(dates: dates(every: 7, count: 2)) == nil)
    }

    @Test("No rhythm when episodes are months apart")
    func tooSparse() {
        #expect(ShowCadence(dates: dates(every: 90, count: 5)) == nil)
    }
}
