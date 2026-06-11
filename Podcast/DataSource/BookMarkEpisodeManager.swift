//
//  BookMarkEpisodeManager.swift
//  Podcast
//
//  Created by Jonathan Mora on 04/06/26.
//


import Foundation
import Observation

private enum KeysFavoriteEpisode {
    static let favorites = "favorite_episodes"
}

@Observable
final class BookMarkEpisodeManager {
    
    static let shared = BookMarkEpisodeManager()
    
    private(set) var episodes: [Episode] = []
    
    private let userDefaults: UserDefaults
    
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.episodes = Self.load(from: userDefaults)
    }
    
    // MARK: - API
    
    func toggle(_ episode: Episode) {
        if let index = episodes.firstIndex(where: { $0.streamUrl == episode.streamUrl }) {
            episodes.remove(at: index)
        } else {
            episodes.append(episode)
        }
        persist()
    }
    
    func isBookMarked(_ episode: Episode) -> Bool {
        episodes.contains(where: { $0.streamUrl == episode.streamUrl })
    }
    
    func delete(_ episode: Episode) {
        episodes.removeAll { $0.streamUrl == episode.streamUrl }
        persist()
    }
    
    // MARK: - Persistence
    
    private func persist() {
        do {
            let data = try JSONEncoder().encode(episodes)
            userDefaults.set(data, forKey: KeysFavoriteEpisode.favorites)
        } catch {
            print("❌ Error encoding favorite episodes:", error)
        }
    }
    
    private static func load(from userDefaults: UserDefaults) -> [Episode] {
        guard let data = userDefaults.data(forKey: KeysFavoriteEpisode.favorites) else { return [] }
        return (try? JSONDecoder().decode([Episode].self, from: data)) ?? []
    }
}
