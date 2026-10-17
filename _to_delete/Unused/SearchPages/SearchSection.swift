//
//  SearchSection.swift
//  Podcast
//

import Foundation

/// The pages that share the Search sheet: the catalog, the podcasts you
/// follow and your favorite episodes. Swipe sideways between them; pull the
/// sheet down (as always) to go back Home.
enum SearchSection: Int, CaseIterable, Identifiable, Sendable {
    case explore
    case following
    case favorites

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .explore:   String(localized: "Search")
        case .following: String(localized: "Following")
        case .favorites: String(localized: "Favorites")
        }
    }

    var systemImage: String {
        switch self {
        case .explore:   "magnifyingglass"
        case .following: "square.stack"
        case .favorites: "heart.fill"
        }
    }

    /// The bar's field says what it searches on each page.
    var placeholder: String {
        switch self {
        case .explore:   String(localized: "Search podcasts")
        case .following: String(localized: "Search what you follow")
        case .favorites: String(localized: "Search your favorites")
        }
    }

    /// Only the catalog page asks iTunes. The others filter what's already
    /// saved on the phone (works offline).
    var searchesCatalog: Bool { self == .explore }
}

/// Filters Following and Favorites with the bar's text: ignores case and
/// accents ("atomo" finds "Átomo"). An empty query keeps everything.
enum LocalSearch {

    static func podcasts(_ podcasts: [Podcast], matching query: String) -> [Podcast] {
        podcasts.filter { matches([$0.trackName, $0.artistName, $0.primaryGenreName], query) }
    }

    static func episodes(_ episodes: [Episode], matching query: String) -> [Episode] {
        episodes.filter { matches([$0.title, $0.author], query) }
    }

    private static func matches(_ fields: [String?], _ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return fields.contains { $0?.localizedStandardContains(query) ?? false }
    }
}
