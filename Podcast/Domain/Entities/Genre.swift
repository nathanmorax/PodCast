//
//  Genre.swift
//  Podcast
//

import Foundation

/// A podcast category. `id` is Apple's genre id (the same ones the iTunes
/// genres API returns), so a choice made in onboarding also matches Search.
struct Genre: Codable, Hashable, Sendable {
    let id: String
    let name: String
}

extension Genre {
    /// The categories offered in onboarding, most listened first. Local and
    /// localized: the screen shows instantly, with no network, in the user's
    /// language. (The genres API returns English names, alphabetically.)
    static let podcastCatalog: [Genre] = [
        Genre(id: "1303", name: String(localized: "Comedy")),
        Genre(id: "1489", name: String(localized: "News")),
        Genre(id: "1488", name: String(localized: "True Crime")),
        Genre(id: "1324", name: String(localized: "Society & Culture")),
        Genre(id: "1321", name: String(localized: "Business")),
        Genre(id: "1512", name: String(localized: "Health & Fitness")),
        Genre(id: "1545", name: String(localized: "Sports")),
        Genre(id: "1487", name: String(localized: "History")),
        Genre(id: "1533", name: String(localized: "Science")),
        Genre(id: "1318", name: String(localized: "Technology")),
        Genre(id: "1304", name: String(localized: "Education")),
        Genre(id: "1301", name: String(localized: "Arts")),
        Genre(id: "1309", name: String(localized: "TV & Film")),
        Genre(id: "1310", name: String(localized: "Music")),
        Genre(id: "1483", name: String(localized: "Fiction")),
        Genre(id: "1305", name: String(localized: "Kids & Family")),
    ]

    /// The catalog genre with this id (its name in the current language).
    static func catalog(id: String) -> Genre? {
        podcastCatalog.first { $0.id == id }
    }
}

#if DEBUG
extension Genre {
    static let mock = Genre(
        id: "",
        name: "Horror"
    )
}
#endif
