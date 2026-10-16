//
//  AppTransition.swift
//  Podcast
//

import SwiftUI

/// How views enter and leave the screen. The timing comes from the
/// animation that drives the change (AppAnimation); these only say *where*.
extension AnyTransition {

    // MARK: - Bottom bar

    /// The whole bar coming up from (or going down to) the bottom edge.
    static var bottomBar: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    /// The mini player stepping aside to the left when Search takes the bar.
    static var barLeadingItem: AnyTransition {
        .move(edge: .leading).combined(with: .opacity)
    }

    /// Small buttons that appear next to the search field (⌄, ✕).
    static var barAccessory: AnyTransition {
        .scale.combined(with: .opacity)
    }

    // MARK: - Player

    /// The full player rising over the app.
    static var playerSheet: AnyTransition {
        .move(edge: .bottom)
    }

    /// Lines in the player's wheel: the new one comes up from below, the old
    /// one leaves through the top, like a rolling drum.
    static var wheelLine: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }

    /// The transcript's controls sliding in from the bottom.
    static var floatingControls: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    // MARK: - Content

    /// A section appearing at the top of a list (e.g. "Recently searched").
    static var sectionReveal: AnyTransition {
        .opacity.combined(with: .move(edge: .top))
    }
}
