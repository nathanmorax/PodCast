//
//  RecentlyPlayedCarousel.swift
//  Podcast
//

import SwiftUI

/// "Recently played": every episode you played as a big card
/// (RecentlyPlayedHero), newest first, one per page with the next one
/// peeking at the right edge; dots under them say where you are.
struct RecentlyPlayedCarousel: View {

    let items: [RecentlyPlayed]
    let onResume: (RecentlyPlayed) -> Void
    let onOpen: (RecentlyPlayed) -> Void
    let onRemove: (RecentlyPlayed) -> Void

    /// The card in view (the dots follow it).
    @State private var currentID: RecentlyPlayed.ID?

    var body: some View {
        VStack(spacing: 14) {
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(items) { item in
                        RecentlyPlayedHero(
                            item: item,
                            onResume: { onResume(item) },
                            onOpen: { onOpen(item) },
                            onRemove: { onRemove(item) }
                        )
                        // Most of the width: the next card peeks.
                        .containerRelativeFrame(.horizontal) { width, _ in
                            min(width - 56, 460)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentID)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .scrollIndicators(.hidden)

            if items.count > 1 {
                PageDots(count: items.count, current: currentIndex)
            }
        }
    }

    private var currentIndex: Int {
        guard let currentID, let index = items.firstIndex(where: { $0.id == currentID }) else { return 0 }
        return index
    }
}

/// ● ○ ○ ○: the current page as a short bar, the others as dots.
private struct PageDots: View {

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
