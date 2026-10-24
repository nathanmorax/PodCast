//
//  LibraryCovers.swift
//  Podcast
//

import SwiftUI

/// The podcasts you follow, as square covers (corners rounded 8) with their
/// name under them. Each cover is what its podcast's page zooms out of and
/// back into.
struct LibraryCovers: View {

    let podcasts: [Podcast]
    let onOpen: (Podcast) -> Void
    /// Whether the covers go past the screen's edge (some are out of view):
    /// Library shows "See All" only then.
    var onOverflowChange: (Bool) -> Void = { _ in }

    static let side: CGFloat = 80
    static let cornerRadius: CGFloat = 8

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 8) {
                ForEach(podcasts, id: \.trackId) { podcast in
                    Button {
                        onOpen(podcast)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Color.clear
                                .frame(width: Self.side, height: Self.side)
                                .overlay { ZoomSourceImage(podcast: podcast, cornerRadius: Self.cornerRadius) }
                                .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
                                .accessibilityHidden(true)
//                            Text(podcast.trackName ?? "")
//                                .font(AppFont.label)
//                                .foregroundStyle(AppColor.Text.primary)
//                                .lineLimit(2, reservesSpace: true)
                        }
                        .frame(width: Self.side, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
        // Wider than what's on screen (margins included): some are hidden.
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentSize.width + geometry.contentInsets.leading + geometry.contentInsets.trailing
                > geometry.containerSize.width + 1
        } action: { _, overflows in
            onOverflowChange(overflows)
        }
    }
}
