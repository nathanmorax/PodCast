//
//  AppAnimation.swift
//  Podcast
//

import SwiftUI
import UIKit

/// Every animation curve in the app, named by what it animates.
///
/// - SwiftUI uses them directly: `.animation(AppAnimation.bar, value: …)` or
///   `withAnimation(AppAnimation.listChange) { … }`.
/// - UIKit uses the same values through `UIView.animate(_:changes:completion:)`
///   (UIView+AppAnimation.swift), so a screen sliding in UIKit and the SwiftUI
///   bar on top of it move with the exact same spring.
/// - Reduce Motion is handled here, once: movement becomes a short cross-fade.
///   Repeating "activity" animations (spinners) are left alone.
///
/// Springs use the iOS 17 `duration`/`bounce` form: `duration` is how long it
/// takes to settle, `bounce` 0 means no overshoot.
///
/// @MainActor: it reads `UIAccessibility.isReduceMotionEnabled`, which UIKit
/// isolates to the main actor, and every caller (views, PlayerManager, the
/// navigation container) already runs there.
@MainActor
enum AppAnimation {

    // MARK: - Navigation (bar and screens)

    /// The bottom bar changing shape: entering Search, typing, folding on scroll.
    static var bar: Animation { motion(.spring(duration: 0.38, bounce: 0.14)) }

    /// The bottom bar appearing/hiding and the space reserved for it.
    static var barVisibility: Animation { motion(.spring(duration: 0.4, bounce: 0.15)) }

    /// A whole screen sliding: Search rising or dropping.
    static var screenSlide: Animation { motion(.spring(duration: 0.42, bounce: 0.1)) }

    /// Letting go of an interactive gesture (tab swipe, pulling Search down).
    /// Springs keep the finger's velocity, so the release continues the motion.
    static var gestureRelease: Animation { motion(.spring(duration: 0.35, bounce: 0.08)) }

    // MARK: - Player

    /// The full player opening (mini → full). A little bounce at most: more
    /// overshoots the top and the screen behind peeks out.
    static var playerPresentation: Animation { motion(.spring(duration: 0.5, bounce: 0.1)) }

    /// The full player closing (button or the end of a drag). No bounce, so
    /// it keeps going down from wherever the finger let go.
    static var playerDismiss: Animation { motion(.spring(duration: 0.38, bounce: 0)) }

    /// Switching between the player and its transcript.
    static var transcriptMode: Animation { motion(.spring(duration: 0.5, bounce: 0.15)) }

    /// Switching tabs under the player's cover (Player · Text · Chapters).
    static var playerTab: Animation { motion(.spring(duration: 0.3, bounce: 0.1)) }

    /// The subtitle moving on to the next sentence.
    static var subtitleLine: Animation { motion(.spring(duration: 0.45, bounce: 0)) }

    /// Switching the transcript between Noche and Papel.
    static var readingTheme: Animation { .easeInOut(duration: 0.3) }

    // MARK: - Onboarding

    /// A genre pill switching on/off.
    static var selection: Animation { motion(.spring(duration: 0.25, bounce: 0.2)) }

    /// The onboarding screen fading in/out over the app.
    static var onboarding: Animation { motion(.easeInOut(duration: 0.35)) }

    // MARK: - Content

    /// Items added to or removed from a list or row (recents, searches).
    static var listChange: Animation { motion(.spring(duration: 0.4, bounce: 0.15)) }

    /// "Read more" / "Show less".
    static var disclosure: Animation { motion(.easeInOut(duration: 0.25)) }

    /// A control changing state: bookmark on/off, download icon.
    static var stateChange: Animation { .easeInOut(duration: 0.25) }

    /// A downloaded cover fading in over its placeholder.
    static var imageAppear: Animation { .easeIn(duration: 0.2) }

    // MARK: - Activity (repeating)

    /// A spinner turning once every `duration` seconds, forever.
    static func spin(duration: TimeInterval) -> Animation {
        .linear(duration: duration).repeatForever(autoreverses: false)
    }

    /// The equalizer bars in the episode header, each with its own delay.
    static func equalizerBar(delay: TimeInterval) -> Animation {
        .easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(delay)
    }

    // MARK: - Reduce Motion

    /// With Reduce Motion on, movement becomes a short cross-fade.
    private static func motion(_ animation: Animation) -> Animation {
        UIAccessibility.isReduceMotionEnabled ? .easeInOut(duration: 0.2) : animation
    }
}
