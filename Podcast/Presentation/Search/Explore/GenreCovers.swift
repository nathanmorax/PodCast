//
//  GenreCovers.swift
//  Podcast
//

import Foundation
import Observation

/// The covers on Search's category tiles: a couple of each category's top
/// shows. Fetched only when a tile first shows (one search per category,
/// the same one its ranking does) and kept for the rest of the session.
@MainActor
@Observable
final class GenreCovers {

    static let shared = GenreCovers()

    /// How many covers a tile shows.
    static let perGenre = 2

    /// Category id → its covers' URLs.
    private(set) var covers: [String: [String]] = [:]

    @ObservationIgnored private var loading: Set<String> = []
    @ObservationIgnored private let repository: any SearchPodcastRepository

    init(repository: any SearchPodcastRepository = PodcastRepositoryImpl(remoteDataSource: PodcastRemoteDataService())) {
        self.repository = repository
    }

    func artwork(for genre: Genre) -> [String] {
        covers[genre.id] ?? []
    }

    /// Fetches the category's covers once; later calls do nothing. On a
    /// failure the tile keeps its plain color and tries again next time.
    func load(_ genre: Genre) async {
        guard covers[genre.id] == nil, !loading.contains(genre.id) else { return }
        loading.insert(genre.id)
        defer { loading.remove(genre.id) }
        guard let podcasts = try? await repository.searchPodcast(query: genre.name) else { return }
        covers[genre.id] = Self.artwork(from: podcasts)
    }

    /// The first shows' covers, no blanks or repeats. Pure, so it's tested.
    nonisolated static func artwork(from podcasts: [Podcast], limit: Int = perGenre) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for podcast in podcasts {
            guard let url = podcast.artworkUrl600, !url.isEmpty, seen.insert(url).inserted else { continue }
            result.append(url)
            if result.count == limit { break }
        }
        return result
    }
}
