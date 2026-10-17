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

    // MARK: - Player

    /// The full player rising over the app.
    static var playerSheet: AnyTransition {
        .move(edge: .bottom)
    }

    /// Subtitle sentences: the new one rises a little and fades in, the old
    /// one keeps going up and fades out. Small offsets, so it reads as a
    /// gentle roll, not a slide.
    static var subtitleLine: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(y: 16)),
            removal: .opacity.combined(with: .offset(y: -16))
        )
    }

    // MARK: - Onboarding

    /// The onboarding screen over the app: fades, and grows a touch on its way
    /// out, as if the app came forward from behind it.
    static var onboarding: AnyTransition {
        .asymmetric(insertion: .opacity, removal: .opacity.combined(with: .scale(scale: 1.04)))
    }

    // MARK: - Content

    /// A section appearing at the top of a list (e.g. "Recently searched").
    static var sectionReveal: AnyTransition {
        .opacity.combined(with: .move(edge: .top))
    }
}
