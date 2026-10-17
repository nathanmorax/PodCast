//
//  PlayerTab.swift
//  Podcast
//

import Foundation

/// The tabs under the player's cover.
enum PlayerTab: Hashable, CaseIterable {
    /// Title, progress bar and play controls.
    case player
    /// The transcript; tap a line to jump there.
    case text
    /// Only when the show notes list chapters.
    case chapters

    var title: LocalizedStringResource {
        switch self {
        case .player: return "Player"
        case .text: return "Text"
        case .chapters: return "Chapters"
        }
    }

    /// The tabs to show: Chapters only if the episode has them.
    static func available(hasChapters: Bool) -> [PlayerTab] {
        hasChapters ? [.player, .text, .chapters] : [.player, .text]
    }
}
