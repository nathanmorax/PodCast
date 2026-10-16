//
//  TestDoubles.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

struct TestError: Error, Equatable {
    var message = "boom"
}

// MARK: - Repository

/// An actor so recorded calls are safe to read from any test, in parallel.
actor MockSearchPodcastRepository: SearchPodcastRepository {
    private(set) var searchedQueries: [String] = []
    private(set) var fetchedFeeds: [String] = []

    private var podcastsResult: Result<[Podcast], Error>
    private var episodesResult: Result<[Episode], Error>

    init(podcasts: [Podcast] = [], episodes: [Episode] = [], error: Error? = nil) {
        if let error {
            podcastsResult = .failure(error)
            episodesResult = .failure(error)
        } else {
            podcastsResult = .success(podcasts)
            episodesResult = .success(episodes)
        }
    }

    func searchPodcast(query: String) async throws -> [Podcast] {
        searchedQueries.append(query)
        return try podcastsResult.get()
    }

    /// Description returned with the episodes by fetchFeed.
    let feedDescription: String? = "A show about tests"

    func fetchFeed(feedURL: String) async throws -> PodcastFeed {
        fetchedFeeds.append(feedURL)
        return PodcastFeed(description: feedDescription, episodes: try episodesResult.get())
    }
}

// MARK: - Fixtures

enum Fixtures {
    static func podcast(id: Int = 1, name: String = "Swift by Sundell") -> Podcast {
        Podcast(
            trackId: id,
            trackName: name,
            artistName: "Artist",
            artworkUrl600: nil,
            primaryGenreName: "Technology",
            trackCount: 10,
            feedUrl: "https://example.com/feed/\(id)"
        )
    }

    static func episode(streamUrl: String = "https://example.com/1.mp3", title: String = "Episode") -> Episode {
        Episode(
            title: title,
            author: "Author",
            pubDate: Date(timeIntervalSince1970: 0),
            description: "",
            streamUrl: streamUrl
        )
    }

    static func episodes(count: Int) -> [Episode] {
        (0..<count).map { episode(streamUrl: "https://example.com/\($0).mp3", title: "Episode \($0)") }
    }
}

// MARK: - Isolation helpers

extension UserDefaults {
    /// A fresh, empty suite per call, so parallel tests never share persisted state.
    static func isolated() -> UserDefaults {
        let name = "PodcastTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}

/// Waits for state that changes from a callback we can't await directly
/// (URLSession completion handlers). Prefer awaiting a Task when one is exposed.
@MainActor
func waitUntil(
    timeout: Duration = .seconds(3),
    sourceLocation: SourceLocation = #_sourceLocation,
    _ condition: () -> Bool
) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now + timeout
    while !condition() {
        guard clock.now < deadline else {
            Issue.record("Condition not met within \(timeout)", sourceLocation: sourceLocation)
            return
        }
        try await Task.sleep(for: .milliseconds(10))
    }
}
