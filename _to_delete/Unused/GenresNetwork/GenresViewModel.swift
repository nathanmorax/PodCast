//
//  GenresViewModel.swift
//  Podcast
//
//  Created by Jonathan MOra on 25/02/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class GenresViewModel {

    @ObservationIgnored private let repository: GenresRepository

    private(set) var genre: [Genre] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Internal read access so tests can await it.
    @ObservationIgnored private(set) var loadTask: Task<Void, Never>?

    init(repository: GenresRepository) {
        self.repository = repository
    }

    func loadGenre() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        let repository = self.repository
        // Inherits @MainActor: the state updates need no hop. The network call
        // itself runs off the main actor (nonisolated async).
        loadTask = Task {
            do {
                genre = try await repository.fetchGenres()
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
