//
//  APIService.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import Foundation
import Alamofire
import FeedKit

protocol PodcastRemoteDataSource {
    func searchPodcasts(
        seacrhPodcast: String,
        completion: @escaping (Result<[Podcast], Error>) -> Void
    )

    func fetchEpisodes(
        feedURL: String,
        completion: @escaping (Result<[Episode], Error>) -> Void
    )
}


class PodcastRemoteDataService: PodcastRemoteDataSource {
    
    private let baseURL = "https://itunes.apple.com/search"

    func searchPodcasts(seacrhPodcast: String, completion: @escaping (Result<[Podcast], any Error>) -> Void) {
        let parameters = ["term": seacrhPodcast, "media": "podcast"]
        
        AF.request(baseURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseData { (dataResponse) in
            
            if let err = dataResponse.error {
                print("Failed to contact yahoo", err)
                return
            }
            
            guard let data = dataResponse.data else { return }
            do {
                let searchResult = try JSONDecoder().decode(SearchResults.self, from: data)
                completion(.success(searchResult.results))
            } catch let decodeErr {
                print("Failed to decode:", decodeErr)
            }
        }
    }
    
    func fetchEpisodes(feedURL: String, completion: @escaping (Result<[Episode], Error>) -> Void) {
        let secureFeedUrl = feedURL.contains("https")
            ? feedURL
            : feedURL.replacingOccurrences(of: "http", with: "https")

        guard let url = URL(string: secureFeedUrl) else { return }

        // Ejecutar en background
        Task.detached(priority: .background) {
            do {
                let feed = try await Feed(url: url)
                
                switch feed {
                case .rss(let rssFeed):
                    let episodes = rssFeed.toEpisodes()
                    await MainActor.run {
                        completion(.success(episodes))
                    }
                case .atom(_):
                    await MainActor.run {
                        completion(.success([]))
                    }
                case .json(_):
                    await MainActor.run {
                        completion(.success([]))
                    }
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }

    }

    
}
