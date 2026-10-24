//
//  RecentlyPlayed+Display.swift
//  Podcast
//

import Foundation

extension RecentlyPlayed {

    /// What's still to go ("23 min"); the whole length when it was finished
    /// (it starts over) or the length isn't known yet.
    var minutesLeftText: String {
        guard let total = episode.durationSeconds, total > 0 else {
            return episode.durationDisplayText
        }
        let left = progress < Self.finishedThreshold ? (1 - progress) * total : total
        return String(localized: "\(max(1, Int((left / 60).rounded(.up)))) min")
    }

    /// The episode's own artwork, when the feed has one.
    var artworkSource: String? {
        guard let image = episode.imageUrl, !image.isEmpty else { return nil }
        return image
    }
}
