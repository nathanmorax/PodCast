//
//  PageDots.swift
//  Podcast
//

import SwiftUI

/// Shared by Home's carousels (Recently played, New episodes).
/// ● ○ ○ ○: the current page as a short bar, the others as dots.
struct PageDots: View {

    let count: Int
    let current: Int

    /// More than this and the dots would cross the screen.
    private static let maxDots = 10

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<min(count, Self.maxDots), id: \.self) { index in
                Capsule()
                    .fill(index == min(current, Self.maxDots - 1)
                          ? AppColor.Text.primary
                          : AppColor.Text.tertiary)
                    .frame(width: index == min(current, Self.maxDots - 1) ? 18 : 6, height: 6)
            }
        }
        .animation(AppAnimation.selection, value: current)
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel(Text("Page \(current + 1) of \(count)"))
    }
}
