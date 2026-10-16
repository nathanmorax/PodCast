//
//  GenresRepository.swift
//  Podcast
//

protocol GenresRepository: Sendable {
    func fetchGenres() async throws -> [Genre]
}
