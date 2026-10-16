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
            
            do {
                let results = try await self.repository.searchPodcast(query: query)
                guard !Task.isCancelled else { return }
                self.podcasts = results
                self.error = nil
                self.lastSearchedQuery = query
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error.localizedDescription
            }
        }
    }
}
