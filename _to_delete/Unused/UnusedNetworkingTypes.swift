//
//  UnusedNetworkingTypes.swift
//  Podcast
//

import Foundation
import Alamofire

// Nothing in the app referenced these types.

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
