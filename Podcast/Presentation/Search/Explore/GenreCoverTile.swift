//
//  GenreCoverTile.swift
//  Podcast
//

import SwiftUI

/// A category in Search's "Browse", like a magazine's section opener: a
/// block in the color of its top show's cover, that cover (and the next
/// one peeking behind it) in the corner, and the category's name in tall
/// white capitals over a dark fade. Two per row, edge to edge.
struct GenreCoverTile: View {

    let genre: Genre
    /// Up to two cover URLs (empty until they load: a plain dark block).
    let covers: [String]

    static let height: CGFloat = 150

    @State private var loadedTint: ArtworkTint?

    private var tint: ArtworkTint? {
        loadedTint ?? ArtworkTintLoader.cachedTint(for: covers.first)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            tint?.color ?? Color(white: 0.22)

            coverStack
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 12)
                .padding(.trailing, 10)

            LinearGradient(
                stops: [.init(color: .clear, location: 0.35), .init(color: .black.opacity(0.7), location: 1)],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(genre.name)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
        }
        .frame(height: Self.height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(genre.name)
        .accessibilityAddTraits(.isButton)
        .task(id: covers.first) {
            guard loadedTint == nil, covers.first != nil else { return }
            let tint = await ArtworkTintLoader.tint(for: covers.first)
            withAnimation(AppAnimation.stateChange) { loadedTint = tint }
        }
    }

    /// The top cover, with the second one offset behind it.
    private var coverStack: some View {
        ZStack(alignment: .topTrailing) {
            if covers.count > 1 {
                cover(covers[1])
                    .offset(x: -16, y: 12)
                    .opacity(0.85)
            }
            if let first = covers.first {
                cover(first)
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            }
        }
        .transition(.opacity)
        .animation(AppAnimation.imageAppear, value: covers)
        .accessibilityHidden(true)
    }

    private func cover(_ url: String) -> some View {
        PodcastImage(source: url)
            .frame(width: 84, height: 84)
            .clipped()
    }
}
