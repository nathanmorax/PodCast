//
//  PodcastServiceError.swift
//  Podcast
//

import Foundation

enum PodcastServiceError: Error {
    case invalidURL
    case decodingFailed(Error)
    case networkFailed(Error)
    case emptyResponse
}
