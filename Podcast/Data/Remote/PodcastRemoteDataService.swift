//
//  PodcastRemoteDataService.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import Foundation
import Alamofire
import FeedKit

class PodcastRemoteDataService: PodcastRemoteDataSource {
    
    private let baseURL = "https://itunes.apple.com/search"
    
    func request<T: Decodable>(_ endpoint: PodcastEndpoint) async throws ->T {
        
        let response = await AF
            .request(endpoint.url, parameters: endpoint.parameters)
            .serializingDecodable(T.self)
            .response
        
        switch response.result {
        case .success(let value):
            return value
        case .failure(let error):
            throw PodcastServiceError.networkFailed(error)
        }
    }
    
    
    func searchPodcast(query: String) async throws -> [Podcast] {
        let result: SearchResults = try await request(.search(query: query))
        return result.results
    }
    
    func fetchEpisodes(feedURL: String) async throws -> [Episode] {
        let secureURL = feedURL.replacingOccurrences(of: "http://", with: "https://")
        
        guard let url = URL(string: secureURL) else {
            throw PodcastServiceError.invalidURL
        }
        
        // Already off the main actor (nonisolated async). A detached task with
        // .background priority made the screen wait longer and couldn't be
        // cancelled when the user left.
        let feed = try await Feed(url: url)
        
        switch feed {
        case .rss(let rssFeed): return rssFeed.toEpisodes()
        case .atom, .json:      return []
        }
    }
    
    
    func fetchGenresPodcast(completion: @escaping (Result<[Genre], Error>) -> Void) {
        let url = "https://itunes.apple.com/WebObjects/MZStoreServices.woa/ws/genres?id=26&l=en"
        
        AF.request(url, method: .get).responseData { dataResponse in
            
            if let err = dataResponse.error {
                print("Failed to contact API", err)
                completion(.failure(err))
                return
            }
            
            guard let data = dataResponse.data else { return }
            
            do {
                let result = try JSONDecoder().decode([String: GenreResponse].self, from: data)
                
                guard let subgenres = result.values.first?.subgenres?.values else {
                    completion(.success([]))
                    return
                }
                
                let genres = subgenres
                    .map { Genre(id: $0.id, name: $0.name) }
                    .prefix(15)
                    .map { $0 }
                
                completion(.success(genres))
            } catch let decodeErr {
                print("Failed to decode:", decodeErr)
                completion(.failure(decodeErr))
            }
        }
    }
}
