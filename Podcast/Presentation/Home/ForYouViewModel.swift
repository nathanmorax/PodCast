//
//  ForYouViewModel.swift
//  Podcast
//

import Observation

/// "For you" in Home: one row of podcasts per genre chosen in onboarding.
///
/// Like a category in Search, each row searches the genre's name for now;
/// when we use a "top by genre" API, only `fetch` changes. Results are kept
/// in memory, so going back to Home doesn't search again.
@MainActor
@Observable
final class ForYouViewModel {

    struct Row: Identifiable {
        let genre: Genre
        let podcasts: [Podcast]
        var id: String { genre.id }
    }

    static let maxRows = 4
    static let podcastsPerRow = 12

    private(set) var rows: [Row] = []
    private(set) var isLoading = false

    @ObservationIgnored private let repository: any SearchPodcastRepository
    @ObservationIgnored private var cache: [String: [Podcast]] = [:]
    /// Internal read access so tests can await it.
    @ObservationIgnored private(set) var loadTask: Task<Void, Never>?

    init(repository: any SearchPodcastRepository = PodcastRepositoryImpl(remoteDataSource: PodcastRemoteDataService())) {
        self.repository = repository
    }

    /// Builds the rows for these genres, leaving out podcasts already in
    /// favorites (they have their own row in Home).
    func load(genres: [Genre], excluding favoriteIDs: Set<Int>) {
        loadTask?.cancel()
        let wanted = Array(genres.prefix(Self.maxRows))
        let missing = wanted.filter { cache[$0.id] == nil }

        // What's cached shows right away.
        rows = makeRows(wanted, excluding: favoriteIDs)
        guard !missing.isEmpty else { return }

        isLoading = true
        let repository = self.repository
        loadTask = Task {
            // All genres at once; a failed one just has no row.
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
            rows = makeRows(wanted, excluding: favoriteIDs)
            isLoading = false
        }
    }

    private func makeRows(_ genres: [Genre], excluding favoriteIDs: Set<Int>) -> [Row] {
        genres.compactMap { genre in
            guard let podcasts = cache[genre.id] else { return nil }
            let shown = podcasts
                .filter { !favoriteIDs.contains($0.trackId) }
                .prefix(Self.podcastsPerRow)
            return shown.isEmpty ? nil : Row(genre: genre, podcasts: Array(shown))
        }
    }
}
