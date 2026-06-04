//
//  FavoritesManager.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//
import Foundation
import Combine

private enum Keys {
    static let favorites = "favorite_podcasts"
}

class FavoritesPodcastManager {
    
    private let userDefaults: UserDefaults
    
    static let shared = FavoritesPodcastManager()
    
    private let favoritesSubject: CurrentValueSubject<[Podcast], Never>
    
    var favoritesPublisher: AnyPublisher<[Podcast], Never> {
        favoritesSubject.eraseToAnyPublisher()
    }
    
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        let initial = Self.load(from: userDefaults, key: Keys.favorites)
        self.favoritesSubject = CurrentValueSubject(initial)
    }
    
    func toggleFavorite(_ podcast: Podcast) {
        var current = favoritesSubject.value
        if let index = current.firstIndex(where: { $0.trackId == podcast.trackId }) {
            current.remove(at: index)
        } else {
            current.append(podcast)
        }
        persist(current)
    }
    
    func isFavorite(_ podcast: Podcast) -> Bool {
        favoritesSubject.value.contains(where: { $0.trackId == podcast.trackId })
    }
    
    func deleteFavorite(_ podcast: Podcast) {
        var current = favoritesSubject.value
        
        current.removeAll { $0.trackId == podcast.trackId }
        
        persist(current)
    }
    
    private func persist(_ podcasts: [Podcast]) {
        do {
            let data = try JSONEncoder().encode(podcasts)
            userDefaults.set(data, forKey: Keys.favorites)
            favoritesSubject.send(podcasts)
        } catch {
            print("❌ Error encoding favorites:", error)
        }
    }
    
    private static func load(from userDefaults: UserDefaults, key: String) -> [Podcast] {
        guard let data = userDefaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Podcast].self, from: data)) ?? []
    }
    
}

//#Preview {
//    SavedEpisodeRow(episode: .mock)
//}
