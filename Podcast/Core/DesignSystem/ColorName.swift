//
//  ColorName.swift
//  Podcast
//

import SwiftUI

/// The name of every color set in Assets.xcassets/Color — the only place in
/// the code where those names are written.
///
/// To add a color: create the color set in Assets.xcassets/Color, add a case
/// here whose raw value is exactly the asset's name, and expose it in AppColor.
/// ColorAssetTests fails if a case has no matching asset.
enum ColorName: String, CaseIterable {

    // MARK: Palette (genre tiles, buttons, status)
    case coralRed
    case dustyBlue

    // MARK: Surfaces and ink
    case screenBackground
    case paper
    case ink
    case accent
    case accentInk
    case surfaceMuted
    case readingBackground
    case readingText
    case surfaceRaised
    case inkOnPastel

    // MARK: Genre cards (pastels; the same in dark mode, with ink on them)
    case genreSky
    case genrePeach
    case genreLinen
    case genreMint
    case genreRose
    case genreLavender
}

extension Color {
    /// `Color(asset: .accent)` instead of `Color("accent")`: no typos.
    init(asset name: ColorName) {
        self.init(name.rawValue)
    }
}
