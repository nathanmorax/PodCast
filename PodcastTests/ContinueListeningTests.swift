//
//  ContinueListeningTests.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

@MainActor
@Suite("Continue listening")
struct ContinueListeningTests {

    private func played(_ url: String, at seconds: TimeInterval, progress: Double) -> RecentlyPlayed {
        RecentlyPlayed(
            episode: Episode(title: url, author: "", pubDate: .now, description: "", streamUrl: url),
            lastPlayedAt: Date(timeIntervalSince1970: seconds),
            progress: progress
        )
    }

    @Test("Only unfinished ones, last played first")
    func unfinishedOnly() {
        let items = [
            played("done", at: 30, progress: 0.99),
            played("half", at: 10, progress: 0.5),
            played("started", at: 20, progress: 0.1)
        ]
        #expect(ContinueListeningSection.unfinished(items).map(\.id) == ["started", "half"])
    }
}
