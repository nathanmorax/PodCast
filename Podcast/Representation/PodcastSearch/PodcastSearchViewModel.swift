//
//  PodcastSearchViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 28/01/26.
//
import UIKit
import Combine

class PodcastSearchViewModel {
    
    private let repository: SearchPodcastRepository
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    
    @Published private(set) var podcasts: [Podcast] = []
    @Published private(set) var episodes: [Episode] = []
    @Published private(set) var error: String?
    private var callCount = 0
    
    let searchText = CurrentValueSubject<String, Never>("")
    private var lastSearchedQuery = ""
    
    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    
    
    init(repository: SearchPodcastRepository) {
        self.repository = repository
        self.setupSearchPipeline()
    }
    
    private func setupSearchPipeline() {
        searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) {
        searchTask?.cancel()
        searchTask = Task {
            do {
                let results = try await repository.searchPodcast(query: query)
                guard !Task.isCancelled else { return }
                await MainActor.run { self.podcasts = results }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { self.error = error.localizedDescription }
            }
        }
    }
    
    
    func loadEpisodes(feedURL: String) {
        Task {
            do {
                let results = try await repository.fetchEpisodes(feedURL: feedURL)
                await MainActor.run {
                    self.episodes = results
                    self.onDataUpdated?()
                }
            } catch {
                await MainActor.run {
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }
    
    //    func searchPodcast(searchPodcast: String) {
    //        callCount += 1
    //        print("🔍 Llamada #\(callCount) con texto: \(searchPodcast)")
    //
    //        repository.searchPodcastsPublisher(searchPodcast: <#T##String#>)
    //
    //        repository.searchPodcasts(searchPodcast: searchPodcast) { [weak self] result in
    //            DispatchQueue.main.async {
    //                switch result {
    //                case .success(let podcasts):
    //                    self?.podcasts = podcasts
    //                    self?.onDataUpdated?()
    //                    print(podcasts)
    //                case .failure(let error):
    //                    print(error)
    //                }
    //            }
    //        }
    //    }
}
