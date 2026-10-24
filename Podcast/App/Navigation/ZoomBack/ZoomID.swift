//
//  ZoomID.swift
//  Podcast
//

import Foundation

/// Names the item a screen zooms out of and back into. Stable values (ids,
/// URLs), never views: the transition looks the item up again when closing,
/// and by then rows may have been reused.
enum ZoomID: Hashable {

    /// A podcast's cover (Library circles, Browse, Search, a category,
    /// Following). The same podcast in two places zooms to the bigger one.
    case podcast(Int)

    /// An episode's cover. The section keeps the same episode in "For you"
    /// and in "Recently played" apart: each closes back into its own card.
    case episode(String, section: Section)

    /// A row or button that opens a list (Following, Favorites, Downloads,
    /// the Inbox).
    case collection(Collection)

    enum Section: Hashable {
        case forYou
        case recentlyPlayed
    }

    enum Collection: Hashable {
        case following
        case favorites
        case downloads
        case inbox
    }
}
