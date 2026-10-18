//
//  GenreCard.swift
//  Podcast
//

import SwiftUI

/// A category in "Explore": a grey square with the covers of its three top
/// podcasts fanned out in the middle, and its name in serif under it.
struct GenreCard: View {

    let genre: Genre
    /// Up to three; missing ones show as soft placeholders while loading.
    let coverURLs: [String]

    static let side: CGFloat = 150
    /// Card + gap + one line of name: the height of a row in the grid.
    static let height: CGFloat = side + 8 + 24

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppColor.Surface.muted)
                .frame(width: Self.side, height: Self.side)
                .overlay { CoverFan(urls: coverURLs) }

            Text(genre.name)
                .font(.system(size: 16, weight: .bold, design: .serif))
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
        }
        .frame(width: Self.side, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(genre.name)
        .accessibilityAddTraits(.isButton)
    }
}

/// Three covers: the top one in front, the next two tilted behind it.
private struct CoverFan: View {

    let urls: [String]

    private struct Slot: Identifiable {
        let index: Int
        let x: CGFloat
        let angle: Double
        var id: Int { index }
    }

    /// Drawn back to front: 2nd and 3rd behind, the 1st on top.
    private static let layout = [
        Slot(index: 1, x: -30, angle: -9),
        Slot(index: 2, x: 30, angle: 9),
        Slot(index: 0, x: 0, angle: 0)
    ]

    var body: some View {
        ZStack {
            ForEach(Self.layout) { slot in
                PodcastImage(
                    source: urls.indices.contains(slot.index) ? urls[slot.index] : nil,
                    placeholder: AppColor.Text.primary.opacity(slot.index == 0 ? 0.12 : 0.07)
                )
                .frame(width: 66, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 6, y: 4)
                .rotationEffect(.degrees(slot.angle))
                .offset(x: slot.x, y: slot.index == 0 ? 0 : 6)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    GenreCard(genre: .mock, coverURLs: ["appicon", "appicon", "appicon"])
        .padding()
}
