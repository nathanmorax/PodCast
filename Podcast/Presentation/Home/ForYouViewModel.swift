//
//  ForYouViewModel.swift
//  Podcast
//

import Observation

/// "For you" in Library: ONE row that mixes the genres chosen in onboarding
/// (one of each in turn), so the screen doesn't grow with every genre.
///
/// Each genre searches its name for now; when we use a "top by genre" API,
/// only `fetch` changes. Results are kept in memory, so going back to
/// Library doesn't search again.
@MainActor
@Observable
final class ForYouViewModel {

    /// Genres used for the mix (the first ones chosen).
    static let maxGenres = 4
    static let maxPodcasts = 12

    private(set) var podcasts: [Podcast] = []
    private(set) var isLoading = false

    @ObservationIgnored private let repository: any SearchPodcastRepository
    @ObservationIgnored private var cache: [String: [Podcast]] = [:]
    /// Internal read access so tests can await it.
    @ObservationIgnored private(set) var loadTask: Task<Void, Never>?

    init(repository: any SearchPodcastRepository = PodcastRepositoryImpl(remoteDataSource: PodcastRemoteDataService())) {
        self.repository = repository
    }

    /// Builds the mix for these genres, leaving out podcasts you already
    /// follow (they're in the pile and in Following).
    func load(genres: [Genre], excluding followingIDs: Set<Int>) {
        loadTask?.cancel()
        let wanted = Array(genres.prefix(Self.maxGenres))
        let missing = wanted.filter { cache[$0.id] == nil }

        // What's cached shows right away.
        podcasts = mix(wanted, excluding: followingIDs)
        guard !missing.isEmpty else {
            isLoading = false
            return
        }

        isLoading = true
        let repository = self.repository
        loadTask = Task {
            // All genres at once; a failed one just adds nothing.
            let fetched = await withTaskGroup(of: (String, [Podcast]?).self) { group in
                for genre in missing {
                    group.addTask { (genre.id, try? await repository.searchPodcast(query: genre.name)) }
                }
                var results: [String: [Podcast]] = [:]
                for await (id, podcasts) in group {
                    if let podcasts { results[id] = podcasts }
                }
                return results
            }
            guard !Task.isCancelled else { return }
            cache.merge(fetched) { _, new in new }
            podcasts = mix(wanted, excluding: followingIDs)
            isLoading = false
        }
    }

    private func mix(_ genres: [Genre], excluding ids: Set<Int>) -> [Podcast] {
        Self.interleave(genres.compactMap { cache[$0.id] }, excluding: ids, limit: Self.maxPodcasts)
    }

    /// Pure: one from each list in turn (1st of each, then 2nd of each…),
    /// without repeats or excluded podcasts, up to `limit`.
    static func interleave(_ lists: [[Podcast]], excluding ids: Set<Int>, limit: Int) -> [Podcast] {
        let lists = lists.map { $0.filter { !ids.contains($0.trackId) } }
        var seen = Set<Int>()
        var result: [Podcast] = []
        var position = 0
        while result.count < limit {
            var anyLeft = false
            for list in lists where position < list.count {
                anyLeft = true
                let podcast = list[position]
                if seen.insert(podcast.trackId).inserted {
                    result.append(podcast)
                    if result.count == limit { break }
                }
            }
            guard anyLeft else { break }
            position += 1
        }
        return result
    }
}
