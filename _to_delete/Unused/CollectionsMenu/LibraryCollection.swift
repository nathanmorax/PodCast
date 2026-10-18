//
//  LibraryCollection.swift
//  Podcast
//

import Foundation

/// What you keep: the podcasts you follow, the episodes you saved, and the
/// ones downloaded. Opened from the collections menu (hold the search button).
enum LibraryCollection: CaseIterable, Identifiable, Hashable, Sendable {
    case following
    case favorites
    case downloads

    var id: Self { self }

    var title: String {
        switch self {
        case .following: String(localized: "Following")
        case .favorites: String(localized: "Favorites")
        case .downloads: String(localized: "Downloads")
        }
    }

    var systemImage: String {
        switch self {
        case .following: "square.stack.3d.up"
        case .favorites: "bookmark"
        case .downloads: "arrow.down.to.line"
        }
    }
}

/// Which pill the finger is over, from the pills' frames. Pure, so tested.
enum CollectionsMenuHitTest {
    static func collection(at point: CGPoint, in frames: [LibraryCollection: CGRect]) -> LibraryCollection? {
        // A little slack around each pill so the finger doesn't have to be exact.
        frames.first { $0.value.insetBy(dx: -8, dy: -4).contains(point) }?.key
    }
}
