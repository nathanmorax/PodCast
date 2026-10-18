//
//  GenresViewModelTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

@MainActor
struct GenresViewModelTests {

    private let genres = [Genre(id: "1", name: "Comedia"), Genre(id: "2", name: "Ciencia")]

    @Test("Loading fills the categories")
    func loadSuccess() async throws {
        let repository = MockGenresRepository(result: .success(genres))
        let sut = GenresViewModel(repository: repository)

        sut.loadGenre()
        #expect(sut.isLoading)
        try await waitUntil { !sut.isLoading }

        #expect(sut.genre.map(\.name) == ["Comedia", "Ciencia"])
        #expect(sut.errorMessage == nil)
    }

    @Test("A failure shows an error and keeps the list empty")
    func loadFailure() async throws {
        let sut = GenresViewModel(repository: MockGenresRepository(result: .failure(TestError())))

        sut.loadGenre()
        try await waitUntil { !sut.isLoading }

        #expect(sut.genre.isEmpty)
        #expect(sut.errorMessage != nil)
    }

    @Test("Retrying after a failure clears the error and loads")
    func retry() async throws {
        let repository = MockGenresRepository(result: .failure(TestError()))
        let sut = GenresViewModel(repository: repository)
        sut.loadGenre()
        try await waitUntil { !sut.isLoading }

        repository.result = .success(genres)
        sut.loadGenre()
        #expect(sut.errorMessage == nil)
        try await waitUntil { !sut.isLoading }

        #expect(sut.genre.count == 2)
        #expect(repository.fetchCount == 2)
    }

    @Test("A second load while one is running doesn't hit the API again")
    func noDuplicateLoads() async throws {
        let repository = MockGenresRepository(result: .success(genres))
        let sut = GenresViewModel(repository: repository)

        sut.loadGenre()
        sut.loadGenre()
        try await waitUntil { !sut.isLoading }

        #expect(repository.fetchCount == 1)
    }
}
