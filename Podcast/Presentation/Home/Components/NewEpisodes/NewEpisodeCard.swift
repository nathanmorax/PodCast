//
//  NewEpisodeCard.swift
//  Podcast
//

import SwiftUI

/// One new episode in Home's carousel, like Apple Podcasts' "New Episodes":
/// the artwork square on top and, under it, a band painted with the
/// artwork's own color holding the show, the title in serif, a line of the
/// description and "27 min · 2 days ago". ▶ sits on the band's corner.
///
/// Only draws and taps; the carousel decides what tapping does.
struct NewEpisodeCard: View {

    let item: PodcastEpisode
    let isPlaying: Bool
    let onOpen: () -> Void
    let onPlay: () -> Void
    let onOpenPodcast: () -> Void

    static let cornerRadius: CGFloat = 22

    /// The artwork's color; read once it loads (cached after that).
    @State private var loadedTint: ArtworkTint?

    private var artwork: String? {
        if let image = item.episode.imageUrl, !image.isEmpty { return image }
        return item.podcast.artworkUrl600
    }

    private var tint: ArtworkTint? {
        loadedTint ?? ArtworkTintLoader.cachedTint(for: artwork)
    }

    private var bandColor: Color { tint?.color ?? AppColor.paper }
    private var textColor: Color { tint?.text ?? AppColor.Text.primary }
    private var secondaryColor: Color { tint?.secondaryText ?? AppColor.Text.secondary }

    var body: some View {
        Button(action: onOpen) {
            VStack(spacing: 0) {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay { PodcastImage(source: artwork, contentMode: .fill) }
                    .clipped()
                    .accessibilityHidden(true)

                band
            }
            .background(bandColor)
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottomTrailing) {
            RowPlayButton(isPlaying: isPlaying, action: onPlay)
                .padding(10)
        }
        .contextMenu {
            Button("Play", systemImage: "play.fill", action: onPlay)
            Button("Go to podcast", systemImage: "square.stack", action: onOpenPodcast)
        }
        .accessibilityHint("Opens the episode")
        .task(id: artwork) {
            guard loadedTint == nil else { return }
            let tint = await ArtworkTintLoader.tint(for: artwork)
            withAnimation(.easeInOut(duration: 0.3)) { loadedTint = tint }
        }
    }

    /// Each line keeps its space, so every card in the row is as tall.
    private var band: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.podcast.trackName ?? item.episode.author)
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(secondaryColor)
                .lineLimit(1)

            Text(item.episode.title)
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(textColor)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            Text(item.episode.description)
                .font(.subheadline)
                .foregroundStyle(secondaryColor)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            HStack(spacing: 4) {
                Text(item.episode.durationDisplayText)
                    .fontWeight(.semibold)
                Text(verbatim: "·")
                Text(item.episode.pubDate, format: .relative(presentation: .named))
            }
            .font(.footnote)
            .foregroundStyle(textColor)
            .lineLimit(1)
            .padding(.top, 2)
            // Room for ▶ on the right.
            .padding(.trailing, 48)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
