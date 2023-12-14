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
       
       DispatchQueue.global(qos: .background).async {
          let parser = FeedParser(URL: url)
         
          parser?.parseAsync(result: { (result) in
              print("Successfully parse feed:")
              
              if let err = result.error {
                  print("Failed to parse XML feed:", err)
                  return
              }
              
              guard let feed = result.rssFeed else { return }
              
              let episodes = feed.toEpisodes()
              completionHandler(episodes)
          })
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
