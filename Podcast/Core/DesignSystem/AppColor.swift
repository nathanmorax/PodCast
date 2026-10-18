//
//  AppColor.swift
//  Podcast
//

import SwiftUI

/// The app's colors. Every one comes from Assets.xcassets (names in
/// ColorName); no hex or RGB values live in code.
enum AppColor {

    // MARK: - Raw palette

    static let limeGreen     = Color(asset: .limeGreen)
    static let dustyRose     = Color(asset: .dustyRose)
    static let coralRed      = Color(asset: .coralRed)
    static let slateGray     = Color(asset: .slateGray)
    static let warmOrange    = Color(asset: .warmOrange)
    static let paleYellow    = Color(asset: .paleYellow)
    static let dustyBlue     = Color(asset: .dustyBlue)
    static let oliveGreen    = Color(asset: .oliveGreen)
    static let burntOrange   = Color(asset: .burntOrange)
    static let charcoalBrown = Color(asset: .charcoalBrown)
    static let lavender      = Color(asset: .lavender)
    static let background    = Color(asset: .background)

    // MARK: - Surfaces and ink

    /// Light grey behind Inicio and Biblioteca.
    static let screenBackground = Color(asset: .screenBackground)
    /// Soft white of the full player.
    static let paper            = Color(asset: .paper)
    /// Near-black text of the full player.
    static let ink              = Color(asset: .ink)
    /// Dark lavender: selected tab, accents on light backgrounds.
    static let lavenderInk      = Color(asset: .lavenderInk)
    /// Transcript page: sepia paper (light) / warm near-black (dark).
    /// Softer than white/black: ~13–14:1 contrast without the glare.
    static let readingBackground = Color(asset: .readingBackground)
    /// Transcript text: warm ink (light) / cream (dark).
    static let readingText       = Color(asset: .readingText)

    // MARK: - Semantic roles

    enum Brand {
        static let primary   = AppColor.background
        static let secondary = AppColor.paleYellow
    }

    enum Status {
        static let success  = AppColor.oliveGreen
        static let warning  = AppColor.burntOrange
        static let critical = AppColor.coralRed
        static let info     = AppColor.dustyBlue
    }

    enum Surface {
        static let primary   = AppColor.paleYellow
        static let secondary = AppColor.dustyRose
        /// Cards on the screen background: white / dark grey.
        static let elevated  = Color(uiColor: .secondarySystemGroupedBackground)
        /// The selected pill of a segmented control, a focused field:
        /// white / a lighter grey than the cards.
        static let raised    = Color(asset: .surfaceRaised)
        /// A quiet grey block (Search's category cards): a step above the
        /// screen in both light and dark.
        static let muted     = Color(uiColor: .systemGray5)
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
        /// On violet or dark fills.
        static let inverse   = Color.white
        /// On pastel or light-violet fills (genre cards, play buttons):
        /// stays dark in dark mode, where `primary` turns light.
        static let onPastel  = Color(asset: .inkOnPastel)
        /// Links and text buttons ("Edit", "Clear", "Try again").
        static let link      = AppColor.lavenderInk
    }

    /// The app's main color: violet. Primary buttons, links, selection,
    /// progress and the navigation bar's buttons use it (AccentColor in the
    /// asset catalog is the same violet, so system controls match).
    enum Accent {
        /// Deep violet: filled buttons, links, selected states, icons.
        static let strong = AppColor.lavenderInk
        /// Light violet: play buttons, progress, highlights.
        static let soft   = AppColor.lavender
        /// A violet tint for backgrounds behind violet icons/text.
        static let wash   = AppColor.lavender.opacity(0.18)
    }
}
