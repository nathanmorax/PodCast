//
//  GenreCoversViewModel.swift
//  Podcast
//

import Observation

/// The covers of each category's top three podcasts, for the gray cards in
/// Search's "Explore".
///
/// Each card asks for its own covers when it appears (only the visible ones
/// make a request) and the answer is kept for the rest of the session, so
/// scrolling back and forth doesn't search again. The iTunes search allows
/// about 20 requests a minute, so this matters.
///
/// Like opening a category, it searches the category's name; the first three
/// results are the top ones.
@MainActor
@Observable
final class GenreCoversViewModel {

    static let coversPerCard = 3

    /// Genre id → artwork URLs (at most three). Missing = not loaded yet.
    private(set) var covers: [String: [String]] = [:]

    @ObservationIgnored private let repository: any SearchPodcastRepository
    @ObservationIgnored private var inFlight: Set<String> = []

    init(repository: any SearchPodcastRepository = PodcastRepositoryImpl(remoteDataSource: PodcastRemoteDataService())) {
        self.repository = repository
    }

    func coverURLs(for genre: Genre) -> [String] {
        covers[genre.id] ?? []
    }

    /// Called from the card's `.task`: cancelled if the card scrolls away
    /// before the answer arrives (it'll ask again when it comes back).
    func load(_ genre: Genre) async {
        guard covers[genre.id] == nil, !inFlight.contains(genre.id) else { return }
        inFlight.insert(genre.id)
        defer { inFlight.remove(genre.id) }

        guard let podcasts = try? await repository.searchPodcast(query: genre.name),
              !Task.isCancelled else { return }
        covers[genre.id] = podcasts
            .compactMap(\.artworkUrl600)
            .filter { !$0.isEmpty }
            .prefix(Self.coversPerCard)
            .map { $0 }
    }
}
