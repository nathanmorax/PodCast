//
//  FavoritesManager.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//
import Foundation

private enum Keys {
    static let favorites = "favorite_podcasts"
}

class FavoritesPodcastManager {
    
    private let userDefaults: UserDefaults
    private let key = Keys.favorites
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func fetchFavoritePodcasts() -> [Podcast] {
        guard let data = userDefaults.data(forKey: key) else { return [] }
        
        do {
            let podcast = try JSONDecoder().decode([Podcast].self, from: data)
            print("📦 Loaded:", podcast.map { $0.trackId })
            return podcast
        } catch {
            print("❌ Error decoding favorites:", error)
            return []
        }
    }
    
    func saveFavorites(_ podcasts: [Podcast]) {
        do {
            let data = try JSONEncoder().encode(podcasts)
            userDefaults.set(data, forKey: key)
            print("💾 Saved:", podcasts.map { $0.trackName })

        } catch {
            print("❌ Error encoding favorites:", error)
        }
    }
    
    func toggleFavorite(_ podcast: Podcast) {
          var current = fetchFavoritePodcasts()
          
        if let index = current.firstIndex(where: { $0.trackName == podcast.trackName }) {
              current.remove(at: index)
          } else {
              current.append(podcast)
          }
          
        saveFavorites(current)
      }
    
    func isFavorite(_ podcast: Podcast) -> Bool {
           fetchFavoritePodcasts().contains(where: { $0.trackId == podcast.trackId })
       }
}
