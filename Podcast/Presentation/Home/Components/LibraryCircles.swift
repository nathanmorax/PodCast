//
//  LibraryCircles.swift
//  Podcast
//

import SwiftUI

/// The podcasts you follow, as round covers with their name under them
/// (like people you follow: the show is the voice you know).
struct LibraryCircles: View {

    let podcasts: [Podcast]
    let onOpen: (Podcast) -> Void

    static let side: CGFloat = 96

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 16) {
                ForEach(podcasts, id: \.trackId) { podcast in
                    Button {
                        onOpen(podcast)
                    } label: {
                        VStack(spacing: 8) {
                            Color.clear
                                .frame(width: Self.side, height: Self.side)
                                .overlay { PodcastImage(source: podcast.artworkUrl600) }
                                .clipShape(Circle())
                                .accessibilityHidden(true)
                            Text(podcast.trackName ?? "")
                                .font(AppFont.label)
                                .foregroundStyle(AppColor.Text.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2, reservesSpace: true)
                        }
                        .frame(width: Self.side)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}

#Preview {
    LibraryCircles(podcasts: [.mock], onOpen: { _ in })
}
