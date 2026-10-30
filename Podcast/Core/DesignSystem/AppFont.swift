//
//  AppFont.swift
//  Podcast
//

import SwiftUI

/// Every text style in the app, by role. Views use these instead of picking
/// sizes, so the same kind of text looks the same everywhere.
///
/// Two typefaces, both Apple's (Apple's guidelines: "Minimize the number of
/// typefaces you use"; the usual rule is one for headings, one for the rest):
///
/// - **New York (serif)** for what you *read as a title*: names of shows,
///   episodes, categories and sections. It's the app's editorial voice.
/// - **SF Pro (sans)** for what you *use or scan*: buttons, labels, meta
///   lines, descriptions, times.
///
/// No third family (no rounded, no custom fonts). Every role is built on a
/// Dynamic Type text style, so it grows with the listener's text size.
///
/// | Role          | Typeface   | Text style (size at default) | Used for                               |
/// |---------------|------------|------------------------------|----------------------------------------|
/// | display       | New York   | largeTitle bold (34)         | Show / category name, onboarding       |
/// | title         | New York   | title bold (28)              | Episode title, screen titles           |
/// | sectionTitle  | New York   | title2 bold (22)             | "Recently played", "For you", sheets   |
/// | itemTitle     | New York   | headline bold (17)           | Episodes and shows in any list         |
/// | cardTitle     | New York   | subheadline bold (15)        | Names under covers                     |
/// | quote         | New York   | title3 italic (20)           | The highlighted line of an episode     |
/// | quoteSmall    | New York   | footnote italic (13)         | First line of an episode in results    |
/// | button        | SF Pro     | callout semibold (16)        | Filled buttons ("Listen", "Continue")  |
/// | label         | SF Pro     | subheadline semibold (15)    | Text buttons, tabs, mini player title  |
/// | body          | SF Pro     | subheadline (15)             | Descriptions, show notes               |
/// | footnote      | SF Pro     | footnote (13)                | Meta lines (date · length), counts     |
/// | caption       | SF Pro     | caption (12)                 | Subtitles under names                  |
/// | captionStrong | SF Pro     | caption semibold (12)        | Pills, badges, "2 days ago"            |
/// | overline      | SF Pro     | caption bold, UPPERCASE (12) | Labels over lists ("RECENT")           |
///
/// Icons (SF Symbols) aren't text roles: size them with `.font(.system(size:))`
/// or `.imageScale` next to the text they go with.
enum AppFont {

    // MARK: New York — titles

    static let display      = Font.system(.headline, design: .serif, weight: .bold)
    static let title        = Font.system(.title, design: .serif, weight: .bold)
    static let sectionTitle = Font.system(.title2, design: .serif, weight: .bold)
    static let cardHeadline = Font.system(.title3, design: .serif, weight: .bold)
    static let itemTitle    = Font.system(.headline, design: .serif, weight: .bold)
    static let cardTitle    = Font.system(.subheadline, design: .serif, weight: .bold)
    static let cardDeck     = Font.system(.callout, design: .serif)
    static let quote        = Font.system(.title3, design: .serif).italic()
    static let quoteSmall   = Font.system(.footnote, design: .serif).italic()

    // MARK: SF Pro Compressed — Home's feed headlines (a magazine cover's
    // tall, tight capitals). Built on text styles: they grow with Dynamic Type.

    static let feedHero   = Font.system(.largeTitle, weight: .bold).width(.compressed)
    static let feedTitle  = Font.system(.title, weight: .bold).width(.compressed)


    // MARK: SF Pro — everything else

    static let button        = Font.system(.callout, weight: .semibold)
    static let label         = Font.system(.subheadline, weight: .semibold)
    static let body          = Font.system(.subheadline)
    static let footnote      = Font.system(.footnote)
    static let caption       = Font.system(.caption)
    static let captionStrong = Font.system(.caption, weight: .semibold)
    static let overline      = Font.system(.caption, weight: .bold)
}

extension View {
    /// The overline style: small, bold, uppercase, slightly spaced.
    func overlineStyle(color: Color = AppColor.Text.secondary) -> some View {
        font(AppFont.overline)
            .textCase(.uppercase)
            .tracking(0.8)
            .foregroundStyle(color)
    }
}
