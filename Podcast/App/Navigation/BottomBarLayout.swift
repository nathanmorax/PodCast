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
/// | Library                       | mini player + search circle  | search field     |
/// | Search                        | search field only            | search field     |
/// | Inside Search (genre/podcast) | nothing                      | nothing          |
struct BottomBarLayout: Equatable {

    enum PlayerPlacement: Equatable {
        /// No mini player.
        case none
        /// In the row, next to the search circle (Library).
        case inline
    }

    let isPlaying: Bool
    let inSearch: Bool
    let isTyping: Bool
    let isSearchDetail: Bool

    /// The mini player only shows on Library. Search is
    /// for searching: no mini player there, nor in the screens it opens.
    var player: PlayerPlacement {
        guard isPlaying, !inSearch, !isSearchDetail else { return .none }
        return .inline
    }

    /// The search row (circle, button or field) is hidden only inside Search
    /// details: there's nothing to search there.
    var showsSearchRow: Bool { !isSearchDetail }

    /// Inside a Search detail with nothing playing the bar has nothing to show.
    var isVisible: Bool { showsSearchRow || player != .none }

    /// Space the lists leave at the bottom for the bar (without margins).
    func height(row: CGFloat) -> CGFloat {
        isVisible ? row : 0
    }
}
