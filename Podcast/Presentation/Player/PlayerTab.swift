//
//  PlayerTab.swift
//  Podcast
//

import Foundation

/// The player's two pages, side by side under the cover (swipe or the
/// dots to move between them).
enum PlayerTab: Hashable, CaseIterable {
    /// Progress bar, play controls and actions.
    case player
    /// The transcript; tap a line to jump there.
    case text

    var title: LocalizedStringResource {
        switch self {
        case .player: return "Player"
        case .text: return "Text"
        }
    }

    /// The page a sideways swipe lands on (nil past either end).
    func next(forward: Bool) -> PlayerTab? {
        let all = Self.allCases
        guard let index = all.firstIndex(of: self) else { return nil }
        let next = forward ? index + 1 : index - 1
        return all.indices.contains(next) ? all[next] : nil
    }
}
