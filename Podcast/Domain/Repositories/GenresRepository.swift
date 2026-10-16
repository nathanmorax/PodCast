//
//  GenresRepository.swift
//  Podcast
//

protocol GenresRepository {
    func fetchGenresPodcast(completion: @escaping (Result<[Genre], Error>) -> Void)
}
