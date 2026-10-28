//
//  AppColor.swift
//  Podcast
//

import SwiftUI

/// The app's colors. Every one comes from Assets.xcassets (names in
/// ColorName); no hex or RGB values live in code.
enum AppColor {

    // MARK: - Raw palette

    static let coralRed      = Color(asset: .coralRed)
    static let slateGray     = Color(asset: .slateGray)
    static let dustyBlue     = Color(asset: .dustyBlue)
    static let oliveGreen    = Color(asset: .oliveGreen)
    static let burntOrange   = Color(asset: .burntOrange)
    static let charcoalBrown = Color(asset: .charcoalBrown)

    // MARK: - Surfaces and ink

    // The palette of the "Binsoo" sketches: warm cream paper, near-black ink,
    // mustard and field green taken from the film photo. Dark mode is the
    // same palette inverted (cream on near-black). Contrast, checked:
    // ink on cream 14.7:1, field green on cream 7.6:1, light green on
    // near-black 10.7:1, ink on mustard 8.7:1.

    /// Warm cream behind every screen (light) / near-black (dark).
    static let screenBackground = Color(asset: .screenBackground)
    /// Lighter cream of the full player and sheets / raised near-black.
    static let paper            = Color(asset: .paper)
    /// Near-black text (light) / cream text (dark).
    static let ink              = Color(asset: .ink)
    /// Mustard: fills (play pills, progress, highlights). Text on it is ink.
    static let accent           = Color(asset: .accent)
    /// Field green: accent text and icons, selected states, links
    /// (deep green on cream / light green on near-black).
    static let accentInk        = Color(asset: .accentInk)
    /// Transcript page: sepia paper (light) / warm near-black (dark).
    /// Softer than white/black: ~13–14:1 contrast without the glare.
    static let readingBackground = Color(asset: .readingBackground)
    /// Transcript text: warm ink (light) / cream (dark).
    static let readingText       = Color(asset: .readingText)

    // MARK: - Semantic roles

    enum Status {
        static let success  = AppColor.oliveGreen
        static let warning  = AppColor.burntOrange
        static let critical = AppColor.coralRed
        static let info     = AppColor.dustyBlue
    }

    enum Surface {
        /// The selected pill of a segmented control, a focused field:
        /// white / a lighter grey than the cards.
        static let raised    = Color(asset: .surfaceRaised)
        /// A quiet block (Search's category cards, unselected chips): a step
        /// darker than the cream (light) / lighter than the black (dark).
        static let muted     = Color(asset: .surfaceMuted)
    }

    /// Text on the app's light surfaces. One ink at three strengths, so
    /// titles, subtitles and hints always match.
    enum Text {
        /// Titles and body.
        static let primary   = AppColor.ink
        /// Subtitles, authors, descriptions.
        static let secondary = AppColor.ink.opacity(0.55)
        /// Hints, timestamps, chevrons, played items.
        static let tertiary  = AppColor.ink.opacity(0.35)
        /// On ink or green fills: cream in light mode, near-black in dark
        /// (always the opposite of the fill, so it stays readable).
        static let inverse   = AppColor.screenBackground
        /// On pastel or light-violet fills (genre cards, play buttons):
        /// stays dark in dark mode, where `primary` turns light.
        static let onPastel  = Color(asset: .inkOnPastel)
    }

    /// The app's accent: field green for text and icons, mustard for fills.
    /// AccentColor in the asset catalog is the same green, so system
    /// controls (back arrow, switches, links) match.
    enum Accent {
        /// Field green: links, selected states, accent icons and text.
        static let strong = AppColor.accentInk
        /// Mustard: play pills, progress, highlights.
        static let soft   = AppColor.accent
        /// A mustard tint behind accent icons/text.
        static let wash   = AppColor.accent.opacity(0.22)
    }
}
