//
//  APIService.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import Foundation
import Alamofire
import FeedKit

enum PodcastServiceError: Error {
    case invalidURL
    case decodingFailed(Error)
    case networkFailed(Error)
    case emptyResponse
}

enum PodcastEndpoint {
    case search(query: String)
    case genres
    
    var url: String {
        switch self {
        case .search, .genres:
            return baseURL
        }
    }
    
    private var baseURL: String {
        switch self {
        case .search:
            return "https://itunes.apple.com/search"
        case .genres:
            return "https://itunes.apple.com/WebObjects/MZStoreServices.woa/ws/genres"
        }
    }
    
    var parameters: [String: String] {
        switch self {
        case .search(let query):
            return ["term": query, "media": "podcast"]
        case .genres:
            return ["id": "26", "l": "en"]
        }
    }
    
    var methotHttp: HTTPMethod {
        switch self {
        case .search, .genres: .post
        }
    }
}

protocol PodcastRemoteDataSource {
    func searchPodcasts(
        seacrhPodcast: String,
        completion: @escaping (Result<[Podcast], Error>) -> Void
    )
    
    func fetchEpisodes(
        feedURL: String,
        completion: @escaping (Result<[Episode], Error>) -> Void
    )
    
    func fetchGenresPodcast(completion: @escaping (Result<[Genre], Error>) -> Void)
    
//    func fecthGenresPodcast() async throws -> [Genre]
    
    func searchPodcast(query: String) async throws -> [Podcast]
    
    func fetchEpisodes(feedURL: String) async throws -> [Episode]
    
}

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
        
        let feed = try await Task.detached(priority: .background) {
            try await Feed(url: url)
        }.value
        
        switch feed {
        case .rss(let rssFeed): return rssFeed.toEpisodes()
        case .atom, .json:      return []
        }
    }
    
//    func fecthGenresPodcast() async throws -> [Genre] {
//        
//        let genre: [String: GenreResponse] = try await request(.genres)
//        
//        let result = try decoder.decode([String: GenreResponse].self, from: data)
//
//    }
    
    
    
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


enum NetworkingError: Error {
    case encodingFailed(innerError: EncodingError)
    case decodingFailed(innerError: DecodingError)
    case invalidStatusCode(innerError: Int)
    case requestFailed(innerError: URLError)
    case otherError(innerError: Error)
}


protocol EndpointProvider {
    var schema: String { get }
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var token: String { get }
    var queryItems: [URLQueryItem]? { get }
    var body: [String: Any]? { get }
    
}
