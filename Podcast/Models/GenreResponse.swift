//
//  GenreResponse.swift
//  Podcast
//
//  Created by Jonathan Mora on 20/03/26.
//

struct GenreResponse: Decodable {
    let id: String
    let name: String
    let subgenres: [String: GenreResponse]?
}

struct Genre: Decodable {
    let id: String
    let name: String
}
