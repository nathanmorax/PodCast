//
//  EpisodeDetailViewModelTests.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

@MainActor
@Suite("EpisodeDetailViewModel")
struct EpisodeDetailViewModelTests {

    private func episode(_ url: String, at seconds: TimeInterval) -> Episode {
        Episode(title: url, author: "", pubDate: Date(timeIntervalSince1970: seconds),
                description: "", streamUrl: url)
    }

    @Test("More from the show: newest first, without this episode")
    func moreLeavesItOut() {
        let current = episode("current", at: 30)
        let more = EpisodeDetailViewModel.more(
            from: [episode("old", at: 10), current, episode("new", at: 40), episode("mid", at: 20)],
            excluding: current
        )
        #expect(more.map(\.streamUrl) == ["new", "mid", "old"])
    }

    @Test("At most five")
    func moreIsCapped() {
        let current = episode("current", at: 0)
        let all = (1...9).map { episode("e\($0)", at: TimeInterval($0)) }
        #expect(EpisodeDetailViewModel.more(from: all, excluding: current).count == EpisodeDetailViewModel.moreLimit)
    }

    @Test("Loads the show's other episodes once")
    func loads() async {
        let current = episode("current", at: 30)
        let repository = MockSearchPodcastRepository(episodes: [current, episode("other", at: 20)])
        let sut = EpisodeDetailViewModel(episode: current, podcast: Fixtures.podcast(id: 1), repository: repository)
        await sut.loadMoreEpisodes()
        #expect(sut.moreEpisodes.map(\.streamUrl) == ["other"])
    }
}
