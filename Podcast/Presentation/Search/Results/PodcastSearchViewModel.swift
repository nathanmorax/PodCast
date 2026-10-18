//
//  PodcastSearchViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 28/01/26.
//
import Foundation
import Observation

@MainActor
@Observable
final class PodcastSearchViewModel {
    
    private(set) var podcasts: [Podcast] = []
    private(set) var episodes: [EpisodeSearchResult] = []
    private(set) var error: String?
    
    @ObservationIgnored private let repository: SearchPodcastRepository
    @ObservationIgnored private let debounce: Duration
    /// Internal read access so tests can `await viewModel.searchTask?.value`.
    @ObservationIgnored private(set) var searchTask: Task<Void, Never>?
    @ObservationIgnored private var lastSearchedQuery = ""
    
    init(repository: SearchPodcastRepository, debounce: Duration = .milliseconds(500)) {
        self.repository = repository
        self.debounce = debounce
    }
    
    /// Call on every keystroke. Each call cancels the pending search, so only
    /// text that stays unchanged for `debounce` reaches the network.
    func search(_ query: String) {
        searchTask?.cancel()
        guard !query.isEmpty else { return }
        
        searchTask = Task { [weak self, debounce] in
            // Debounce: sleep throws CancellationError if another keystroke arrives.
            do {
                try await Task.sleep(for: debounce)
            } catch {
                return
            }
            
            // Equivalent to removeDuplicates(): skip a query we already have results for.
            guard let self, query != self.lastSearchedQuery else { return }
            
            // Both at once. Episodes are extra: if only they fail, the
            // podcasts still show (with no Episodes section).
            let repository = self.repository
            async let foundEpisodes = try? repository.searchEpisodes(query: query)
            do {
                let results = try await repository.searchPodcast(query: query)
                let episodes = await foundEpisodes ?? []
                guard !Task.isCancelled else { return }
                self.podcasts = results
                self.episodes = episodes
                self.error = nil
                self.lastSearchedQuery = query
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error.localizedDescription
            }
        }
    }
}
