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

    /// iTunes' English genre names (`Podcast.primaryGenreName`) → catalog id.
    /// Subgenres map to their parent ("Improv" → Comedy).
    private static let iTunesNames: [String: String] = [
        "comedy": "1303", "comedy interviews": "1303", "improv": "1303", "stand-up": "1303",
        "news": "1489", "daily news": "1489", "politics": "1489", "news commentary": "1489",
        "true crime": "1488",
        "society & culture": "1324", "documentary": "1324", "personal journals": "1324", "relationships": "1324",
        "business": "1321", "careers": "1321", "entrepreneurship": "1321", "investing": "1321", "management": "1321",
        "health & fitness": "1512", "mental health": "1512", "fitness": "1512", "nutrition": "1512",
        "sports": "1545", "soccer": "1545", "football": "1545", "basketball": "1545",
        "history": "1487",
        "science": "1533", "natural sciences": "1533", "nature": "1533", "physics": "1533", "astronomy": "1533",
        "technology": "1318",
        "education": "1304", "self-improvement": "1304", "language learning": "1304", "how to": "1304",
        "arts": "1301", "books": "1301", "design": "1301",
        "tv & film": "1309", "film reviews": "1309", "tv reviews": "1309",
        "music": "1310", "music commentary": "1310",
        "fiction": "1483", "drama": "1483", "science fiction": "1483",
        "kids & family": "1305", "parenting": "1305",
    ]

    /// The catalog id for a podcast's iTunes genre, if it's one we offer.
    static func catalogID(forITunesGenre name: String?) -> String? {
        guard let name else { return nil }
        return iTunesNames[name.lowercased()]
    }

    /// The catalog genre with this id (its name in the current language).
    static func catalog(id: String) -> Genre? {
        podcastCatalog.first { $0.id == id }
    }

    /// Search's "Explore": the whole catalog, the listener's interests first
    /// (in their order), then the rest as the catalog lists them.
    static func explore(interests: [Genre]) -> [Genre] {
        let chosen = Set(interests.map(\.id))
        return interests + podcastCatalog.filter { !chosen.contains($0.id) }
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

extension Podcast {
    /// Its category in the app's language ("Ciencia" for "Science"); the
    /// API's own name when it isn't one of the catalog's. For display.
    var genreName: String? {
        catalogGenre?.name ?? primaryGenreName.flatMap { $0.isEmpty ? nil : $0 }
    }

    /// Its category as one of the catalog's, when it is one.
    var catalogGenre: Genre? {
        Genre.catalogID(forITunesGenre: primaryGenreName).flatMap(Genre.catalog(id:))
    }
}
