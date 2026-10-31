//
//  ArtworkWash.swift
//  Podcast
//

import SwiftUI

/// The soft wash of an artwork's color at the top of a page (a podcast's,
/// an episode's), fading into the page's background. Its color also runs
/// far above the top, so pulling the page down past the top shows more of
/// the color instead of the plain background.
struct ArtworkWash: View {

    let color: Color?
    /// How tall the fade is, from the top of the page.
    var height: CGFloat = 360

    /// How much color sits above the top, for pulls past it.
    private static let overscroll: CGFloat = 1200

    var body: some View {
        let top = (color ?? AppColor.Surface.muted).opacity(0.85)
        VStack(spacing: 0) {
            top
                .frame(height: Self.overscroll)
            LinearGradient(colors: [top, AppColor.screenBackground], startPoint: .top, endPoint: .bottom)
                .frame(height: height)
        }
        .offset(y: -Self.overscroll)
        .frame(height: height, alignment: .top)
        .accessibilityHidden(true)
    }
}
