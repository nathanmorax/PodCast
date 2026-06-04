//
//  GenresViewModel.swift
//  Podcast
//
//  Created by Jonathan MOra on 25/02/26.
//
import UIKit

class GenresViewModel {
    
    private let repository: GenresRepository
    
    private(set) var genre: [Genre] = []
    
    
    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    
    init(repository: GenresRepository) {
        self.repository = repository
    }
    
    func loadGenre() {
        
        repository.fetchGenresPodcast { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let genre):
                    self?.onDataUpdated?()
                    self?.genre = genre
                    print(genre)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}
