//
//  GenresViewModel.swift
//  Podcast
//
//  Created by Jonathan MOra on 25/02/26.
//
import Foundation

@MainActor
final class GenresViewModel {
    
    private let repository: GenresRepository
    
    private(set) var genre: [Genre] = []
    
    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    
    init(repository: GenresRepository) {
        self.repository = repository
    }
    
    func loadGenre() {
        repository.fetchGenresPodcast { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch result {
                case .success(let genre):
                    // Update the data FIRST, then notify: the controller's
                    // reloadData() reads `genre` inside the callback.
                    self.genre = genre
                    self.onDataUpdated?()
                case .failure(let error):
                    print(error)
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }
}
