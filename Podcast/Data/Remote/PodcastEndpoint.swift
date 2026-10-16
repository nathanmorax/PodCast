//
//  PodcastEndpoint.swift
//  Podcast
//

import Foundation
import Alamofire

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
    
    var parameters: [String: Any] {
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
