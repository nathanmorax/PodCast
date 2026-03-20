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
    
    private(set) var podcasts: [Podcast] = []
    private(set) var episodes: [Episode] = []
    private var callCount = 0
    
    let searchText = CurrentValueSubject<String, Never>("")
    private var lastSearchedQuery = ""
    
    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    
    let favoritesPodcastmanager = FavoritesPodcastManager(userDefaults: .standard)

    
    init(repository: SearchPodcastRepository) {
        self.repository = repository
        self.setupSearchPipeLine()
    }
    
    private func setupSearchPipeLine() {
        searchText
            .handleEvents(receiveOutput: { print("📨 Recibido: \($0)") })
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .sink { [weak self] query in
                guard let self = self else { return }
                    guard query != self.lastSearchedQuery else {
                        print("⏭️ Query repetida, se omite: \(query)")
                        return
                    }
                    self.lastSearchedQuery = query
                    self.searchPodcast(searchPodcast: query)
            }
            .store(in: &cancellables)
    }
    
    
    func loadEpisodes(feedURL: String) {
        repository.fetchEpisodes(feedURL: feedURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let episodes):
                    self?.episodes = episodes
                    self?.onDataUpdated?()
                    print(episodes)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    func searchPodcast(searchPodcast: String) {
        callCount += 1
        print("🔍 Llamada #\(callCount) con texto: \(searchPodcast)")
        repository.searchPodcasts(searchPodcast: searchPodcast) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let podcasts):
                    self?.podcasts = podcasts
                    self?.onDataUpdated?()
                    print(podcasts)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}
