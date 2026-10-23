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
/// | A podcast's page (any stack)  | mini player only, full width | nothing          |
/// | Inside Search (genre)         | nothing                      | nothing          |
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
    /// A podcast's page (its episodes), opened from Library or from Search.
    var isPodcastPage: Bool = false

    /// The mini player shows on Library and on a podcast's page (you browse
    /// its episodes while one plays). Search is for searching: no mini
    /// player there, nor in the other screens it opens.
    var player: PlayerPlacement {
        guard isPlaying else { return .none }
        if isPodcastPage { return .inline }
        guard !inSearch, !isSearchDetail else { return .none }
        return .inline
    }

    /// The search row (circle, button or field) is hidden inside Search
    /// details and on a podcast's page: there's nothing to search there.
    var showsSearchRow: Bool { !isSearchDetail && !isPodcastPage }

    /// Inside a Search detail with nothing playing the bar has nothing to show.
    var isVisible: Bool { showsSearchRow || player != .none }

    /// Space the lists leave at the bottom for the bar (without margins).
    func height(row: CGFloat) -> CGFloat {
        isVisible ? row : 0
    }
}
