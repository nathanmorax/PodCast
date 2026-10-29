//
//  BrowseViewModel.swift
//  Podcast
//

import Foundation
import Observation

/// "Browse podcasts" in Library: a chip per category and a row of shows for
/// the chosen one. "Picked for you" mixes the top shows of the listener's
/// interests.
///
/// Each chip searches once and keeps its answer for the session (the iTunes
/// search allows about 20 requests a minute).
@MainActor
@Observable
final class BrowseViewModel {

    enum Chip: Hashable, Identifiable {
        case pickedForYou
        case genre(Genre)

        var id: String {
            switch self {
            case .pickedForYou: "picked"
            case .genre(let genre): genre.id
            }
        }
    }

    /// Shows in a category's row.
    static let rowCount = 12
    /// "Picked for you": this many shows from each of the first interests.
    static let perInterest = 4
    static let pickedInterests = 3
    /// Category chips when the listener hasn't chosen interests.
    static let defaultChips = 6

    private(set) var podcasts: [Chip: [Podcast]] = [:]
    private(set) var loading: Set<Chip> = []
    private(set) var failed: Set<Chip> = []

    @ObservationIgnored private let repository: any SearchPodcastRepository

    init(repository: any SearchPodcastRepository = PodcastRepositoryImpl(remoteDataSource: PodcastRemoteDataService())) {
        self.repository = repository
    }

    /// "Picked for you", then the listener's interests (or the most listened
    /// categories when there are none).
    static func chips(interests: [Genre]) -> [Chip] {
        let genres = interests.isEmpty ? Array(Genre.podcastCatalog.prefix(defaultChips)) : interests
        return [.pickedForYou] + genres.map(Chip.genre)
    }

    func podcasts(for chip: Chip) -> [Podcast] {
        podcasts[chip] ?? []
    }

    /// Called from the row's `.task(id:)`: a chip already loaded (or loading)
    /// doesn't search again.
    func load(_ chip: Chip, interests: [Genre]) async {
        guard podcasts[chip] == nil, !loading.contains(chip) else { return }
        loading.insert(chip)
        failed.remove(chip)
        defer { loading.remove(chip) }

        do {
            let result: [Podcast]
            switch chip {
            case .genre(let genre):
                result = Array(try await repository.searchPodcast(query: genre.name).prefix(Self.rowCount))
            case .pickedForYou:
                result = try await picked(from: interests)
            }
            guard !Task.isCancelled else { return }
            podcasts[chip] = result
        } catch {
            guard !Task.isCancelled else { return }
            failed.insert(chip)
        }
    }

    /// The top few of each interest, taking turns (one of each, then the
    /// next of each), with no show twice.
    private func picked(from interests: [Genre]) async throws -> [Podcast] {
        let genres = (interests.isEmpty ? Genre.podcastCatalog : interests).prefix(Self.pickedInterests)
        var lists: [[Podcast]] = []
        for genre in genres {
            lists.append(Array(try await repository.searchPodcast(query: genre.name).prefix(Self.perInterest)))
        }
        var seen = Set<Int>()
        var result: [Podcast] = []
        for index in 0..<Self.perInterest {
            for list in lists where index < list.count {
                let podcast = list[index]
                if seen.insert(podcast.trackId).inserted { result.append(podcast) }
            }
        }
        return result
    }
}
