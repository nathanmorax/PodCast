//
//  AppFont.swift
//  Podcast
//

import SwiftUI

/// Every text style in the app, by role. Views use these instead of picking
/// sizes, so the same kind of text looks the same everywhere.
///
/// | Role          | Size / weight      | Used for                                |
/// |---------------|--------------------|-----------------------------------------|
/// | display       | 34 heavy           | Onboarding question                     |
/// | hero          | 32 heavy           | Podcast name over its cover             |
/// | screenTitle   | 28 bold            | Home / Library / Search (left title)    |
/// | sectionTitle  | 22 bold            | "Continue listening", "For you"…        |
/// | sheetTitle    | 19 bold            | Titles in sheets (episode, about)       |
/// | headline      | 17 semibold        | Episode titles in lists, menu rows      |
/// | cardTitle     | 16 semibold        | Cards and search results                |
/// | button        | 16 semibold        | Filled buttons ("Listen to podcast")    |
/// | body          | 15 regular         | Descriptions, show notes                |
/// | link          | 15 semibold        | Text buttons ("Edit", "Try again")      |
/// | itemTitle     | 14 semibold        | Tiles and small rows                    |
/// | callout       | 14 regular         | Short descriptions in rows              |
/// | footnote      | 13 regular         | Meta lines (date · length)              |
/// | overline      | 13 bold, uppercase | Labels over lists ("312 EPISODES")      |
/// | caption       | 12 regular         | Subtitles under tiles (author)          |
/// | captionStrong | 12 semibold        | Pills, badges, durations                |
///
/// Editorial (serif, New York) — the podcast page and episode details read
/// like a magazine:
///
/// | Role             | Size / weight     | Used for                              |
/// |------------------|-------------------|---------------------------------------|
/// | editorialHero    | 40 bold serif     | Podcast name over its cover           |
/// | editorialTitle   | 28 bold serif     | Episode title in its details          |
/// | editorialItem    | 18 bold serif     | Episode titles in the list            |
/// | editorialQuote   | 20 italic serif   | The highlighted line of an episode    |
enum AppFont {
    static let display       = Font.system(size: 34, weight: .heavy)
    static let hero          = Font.system(size: 32, weight: .heavy)
    static let screenTitle   = Font.system(size: 28, weight: .bold)
    static let sectionTitle  = Font.system(size: 22, weight: .bold)
    static let sheetTitle    = Font.system(size: 19, weight: .bold)
    static let headline      = Font.system(size: 17, weight: .semibold)
    static let cardTitle     = Font.system(size: 16, weight: .semibold)
    static let button        = Font.system(size: 16, weight: .semibold)
    static let body          = Font.system(size: 15)
    static let link          = Font.system(size: 15, weight: .semibold)
    static let itemTitle     = Font.system(size: 14, weight: .semibold)
    static let callout       = Font.system(size: 14)
    static let footnote      = Font.system(size: 13)
    static let overline      = Font.system(size: 13, weight: .bold)
    static let caption       = Font.system(size: 12)
    static let captionStrong = Font.system(size: 12, weight: .semibold)

    static let editorialHero  = Font.system(size: 40, weight: .bold, design: .serif)
    static let editorialTitle = Font.system(size: 28, weight: .bold, design: .serif)
    static let editorialItem  = Font.system(size: 18, weight: .bold, design: .serif)
    static let editorialQuote = Font.system(size: 20, weight: .regular, design: .serif).italic()
}

extension View {
    /// The overline style: small, bold, uppercase, slightly spaced.
    func overlineStyle(color: Color = AppColor.Text.secondary) -> some View {
        font(AppFont.overline)
            .textCase(.uppercase)
            .tracking(0.5)
            .foregroundStyle(color)
    }
}
