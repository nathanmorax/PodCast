//
//  HomePostsTests.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

@Suite("HomePosts")
struct HomePostsTests {

    private let now = Date(timeIntervalSince1970: 1_000_000)

    private func item(_ url: String, show: Int = 1) -> PodcastEpisode {
        PodcastEpisode(
            podcast: Fixtures.podcast(id: show),
            episode: Episode(title: url, author: "", pubDate: now, description: "", streamUrl: url)
        )
    }

    private func played(_ url: String, at seconds: TimeInterval, progress: Double) -> RecentlyPlayed {
        RecentlyPlayed(
            episode: Episode(title: url, author: "Host", pubDate: now, description: "", streamUrl: url),
            lastPlayedAt: Date(timeIntervalSince1970: seconds),
            progress: progress
        )
    }

    @Test("Posts keep their show and stop at the limit")
    func posts() {
        let posts = HomePosts.posts((1...30).map { item("e\($0)", show: 4) })
        #expect(posts.count == HomePosts.limit)
        #expect(posts.first?.podcast?.trackId == 4)
        #expect(posts.first?.section == .feed)
        #expect(posts.first?.progress == nil)
    }

    @Test("Continue: started, not done, last played first, with how far along")
    func continuePosts() {
        let posts = HomePosts.continuePosts([
            played("old", at: 1, progress: 0.5), played("done", at: 3, progress: 0.99),
            played("new", at: 2, progress: 0.2), played("zero", at: 4, progress: 0)
        ])
        #expect(posts.map(\.id) == ["new", "old"])
        #expect(posts.first?.progress == 0.2)
        #expect(posts.first?.podcast == nil)
        #expect(posts.first?.section == .recentlyPlayed)
    }
}
