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

    init(repository: GenresRepository) {
        self.repository = repository
    }

    func loadGenre() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        repository.fetchGenresPodcast { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let genre):
                    self.genre = genre
                case .failure(let error):
                    print(error)
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
