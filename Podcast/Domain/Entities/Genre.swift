//
//  Genre.swift
//  Podcast
//

import Foundation

struct Genre: Decodable {
    let id: String
    let name: String
}

#if DEBUG
extension Genre {
    static let mock = Genre(
        id: "",
        name: "Horror"
    )
}
#endif
