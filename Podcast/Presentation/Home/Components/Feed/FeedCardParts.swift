//
//  FeedCardParts.swift
//  Podcast
//

import SwiftUI

/// The pieces Home's image cards share: the artwork filling the card with a
/// dark fade at the bottom (so white text reads on any cover), the white
/// label, and the "SHOW · Genre · 48 min" line.

/// The artwork edge to edge (cropped to the card), darker toward the
/// bottom where the text sits.
struct FeedArtworkBackground: View {

    let source: String?

    var body: some View {
        Rectangle()
            .fill(Color.black)
            .overlay { PodcastImage(source: source, contentMode: .fill) }
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0.25),
                        .init(color: .black.opacity(0.82), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .accessibilityHidden(true)
    }
}

/// "NEW": small black capitals on a white tag, like a magazine's sticker.
struct FeedTagLabel: View {

    let tag: FeedTag

    var body: some View {
        Text(tag.title)
            .font(.caption2.weight(.bold))
            .textCase(.uppercase)
            .tracking(1)
            .foregroundStyle(.black)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.white)
    }
}

/// "FIELD NOTES  Science · 48 min": the show in bold capitals, the rest
/// lighter.
struct FeedMetaLine: View {

    let show: String
    let details: [String]

    var body: some View {
        let rest = details.filter { !$0.isEmpty }.joined(separator: " · ")
        HStack(spacing: 6) {
            Text(show)
                .fontWeight(.bold)
                .textCase(.uppercase)
            if !rest.isEmpty {
                Text(rest)
                    .opacity(0.8)
            }
        }
        .font(.footnote)
        .lineLimit(1)
    }
}

extension PodcastEpisode {

    /// The episode's own artwork, or its show's.
    var feedArtwork: String? {
        if let image = episode.imageUrl, !image.isEmpty { return image }
        return podcast.artworkUrl600
    }

    var showName: String { podcast.trackName ?? episode.author }
}
