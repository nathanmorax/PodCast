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


import SwiftUI

struct SavedEpisodesView: View {
    
    private var favorites: BookMarkEpisodeManager { .shared }
    
    var body: some View {
        NavigationStack {
            Group {
                if favorites.episodes.isEmpty {
                    emptyState
                } else {
//                    episodesList
                }
            }
            .navigationTitle("Saved")
        }
    }
    
    // MARK: - Empty state
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.gray.opacity(0.4))
            Text("No saved episodes yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - List
    
//    private var episodesList: some View {
//        List {
//            ForEach(favorites.episodes, id: \.streamUrl) { episode in
//                SavedEpisodeRow(episode: episode)
//                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
//                    .listRowSeparator(.hidden)
//                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                        Button(role: .destructive) {
//                            favorites.delete(episode)
//                        } label: {
//                            Label("Delete", systemImage: "trash")
//                        }
//                    }
//            }
//        }
//        .listStyle(.plain)
//    }
}

import SwiftUI

struct SavedEpisodeRow: View {
    
    let episode: Episode
    let onAction: (SavedEpisodeAction) -> Void

    var body: some View {
        HStack(spacing: 12) {
            
            PodcastImage(source: episode.imageUrl)
//                .saturation(0)
                .frame(width: 95, height: 95)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(episode.author)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.gray)
                
                Text(episode.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(episode.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                

                
                HStack {
                    
                    Button {
                        
                        onAction(.playAndPause)
                        
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10, weight: .semibold))

                            Text(episode.duration ?? "0.0")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button {
                        onAction(.removeBookmark)
                    } label: {
                        Image(systemName: "bookmark.fill")
                    }
                    .foregroundStyle(.black)


                    Button {
                        
                    } label: {
                        Image(systemName: "arrow.down.app.fill")
                    }
                    .foregroundStyle(.black)

                    
                }
                
            }
        }
    }
}

//#Preview {
//    SavedEpisodeRow(episode: .mock)
//}
