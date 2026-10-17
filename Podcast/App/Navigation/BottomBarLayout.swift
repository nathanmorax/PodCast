//
//  BottomBarLayout.swift
//  Podcast
//

import CoreGraphics

/// What the bottom bar shows, decided from where you are and whether
/// something is playing. Pure value: no UI, so it's unit tested.
///
/// | Where                         | Playing                      | Not playing      |
/// |-------------------------------|------------------------------|------------------|
/// | Inicio / Biblioteca           | mini player + search circle  | search field     |
/// | Search (not typing)           | field + small mini player    | search field     |
/// | Search (typing)               | search field only            | search field     |
/// | Inside Search (genre/podcast) | mini player only             | nothing          |
struct BottomBarLayout: Equatable {

    enum PlayerPlacement: Equatable {
        /// No mini player.
        case none
        /// In the row, next to the search circle (tabs).
        case inline
        /// Small (artwork + play), right of the search field (Search).
        case trailing
        /// The only thing in the bar (screens opened from Search).
        case alone
    }

    let isPlaying: Bool
    let inSearch: Bool
    let isTyping: Bool
    let isSearchDetail: Bool

    var player: PlayerPlacement {
        guard isPlaying else { return .none }
        if isSearchDetail { return .alone }
        if !inSearch { return .inline }
        return isTyping ? .none : .trailing
    }

    /// The search row (circle, button or field) is hidden only inside Search
    /// details: there's nothing to search there.
    var showsSearchRow: Bool { !isSearchDetail }

    /// Inside a Search detail with nothing playing the bar has nothing to show.
    var isVisible: Bool { showsSearchRow || player != .none }

    /// Space the lists leave at the bottom for the bar (without margins).
    func height(row: CGFloat, playerRow: CGFloat, spacing: CGFloat) -> CGFloat {
        switch player {
        case .alone, .trailing: return row
        case .none, .inline: return isVisible ? row : 0
        }
    }
}
