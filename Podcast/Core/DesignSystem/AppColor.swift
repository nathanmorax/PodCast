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
        static let elevated  = Color.white
    }

    enum Text {
        static let primary   = AppColor.charcoalBrown
        static let secondary = AppColor.slateGray
        static let inverse   = Color.white
    }

    /// Tile colors for genres.
    /// - slateGray is NOT here: it's the screen background, so those tiles looked empty.
    /// - charcoalBrown is NOT here: it's the text color, so labels on it were unreadable.
    static let palette: [Color] = [
        limeGreen, dustyRose, coralRed, warmOrange,
        paleYellow, dustyBlue, oliveGreen, burntOrange, lavender
    ]
}
