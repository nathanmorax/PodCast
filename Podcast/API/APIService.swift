//
//  APIService.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import Foundation
import Alamofire
import FeedKit

class APIService {
    let baseiTunesSearchURL = "https://itunes.apple.com/search"
    
    static let shared = APIService()
    
    func fetchEpisodes(feedUrl: String, completionHandler: @escaping ([Episode]) -> ()) {
        
        let secureFeedUrl = feedUrl.contains("https") ? feedUrl : feedUrl.replacingOccurrences(of: "http", with: "https")
        
        guard let url = URL(string: secureFeedUrl) else { return }
        
        //MARK: - Pasar esta funcion a Async Await
        
        Task {
            do {
                let feed = try await Feed(url: url)
                
                print("Successfully parse feed:")
                
                switch feed {
                case .rss(let rssFeed):
                    let episodes = rssFeed.toEpisodes()
                    await MainActor.run {
                        completionHandler(episodes)
                    }
                case .atom(_):
                    print("Feed tipo Atom no soportado actualmente")
                case .json(_):
                    print("Feed tipo JSON no soportado actualmente")
                }
                
            } catch {
                print("Failed to parse XML feed:", error)
            }
        }
    }
    
    func fetchPodcast(searchText: String, completionHandler: @escaping ([Podcast]) -> ()) {
        let parameters = ["term": searchText, "media": "podcast"]
        
        AF.request(baseiTunesSearchURL, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil).responseData { (dataResponse) in
            
            if let err = dataResponse.error {
                print("Failed to contact yahoo", err)
                return
            }
            
            guard let data = dataResponse.data else { return }
            do {
                let searchResult = try JSONDecoder().decode(SearchResults.self, from: data)
                completionHandler(searchResult.results)
            } catch let decodeErr {
                print("Failed to decode:", decodeErr)
            }
        }
    }
    
}
