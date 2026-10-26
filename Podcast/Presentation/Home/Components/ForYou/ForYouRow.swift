//
//  ForYouRow.swift
//  Podcast
//

import SwiftUI

/// "For you": the latest episodes of the podcasts you follow, as wide cards
/// that snap one by one, the next one peeking at the right edge.
///
/// Tapping a card opens the episode, zooming out of the card and back into
/// it (ZoomSourceHost + pushZooming in HomeController). The ••• (and holding
/// the card) offers Play and Go to podcast.
struct ForYouRow: View {

    let items: [PodcastEpisode]
    let onOpen: (PodcastEpisode) -> Void
    let onPlay: (Episode) -> Void
    let onOpenPodcast: (Podcast) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(items) { item in
                    ZoomSourceHost(
                        id: .episode(item.episode.streamUrl, section: .forYou),
                        cornerRadius: ForYouCard.cornerRadius
                    ) {
                        ForYouRowCard(
                            item: item,
                            onOpen: { onOpen(item) },
                            onPlay: { onPlay(item.episode) },
                            onOpenPodcast: { onOpenPodcast(item.podcast) }
                        )
                    }
                    // Most of the screen's width: the next card peeks.
                    .containerRelativeFrame(.horizontal) { width, _ in
                        min(width - 26, 460)
                    }
                    .frame(height: ForYouCard.height)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}

/// The card as a Button, with the ••• over it (not inside the Button's
/// label: a Menu inside a label fights the Button for the tap). Reads the
/// artwork's color, which both the card and the ••• use.
private struct ForYouRowCard: View {

    let item: PodcastEpisode
    let onOpen: () -> Void
    let onPlay: () -> Void
    let onOpenPodcast: () -> Void

    /// Read once the artwork loads; already known: no fade.
    @State private var loadedTint: ArtworkTint?

    private var artworkSource: String? { ForYouCard.artworkSource(for: item) }

    private var tint: ArtworkTint? {
        loadedTint ?? ArtworkTintLoader.cachedTint(for: artworkSource)
    }

    var body: some View {
        Button(action: onOpen) {
            ForYouCard(item: item, tint: tint)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the episode")
        .contextMenu { actions }
        .overlay(alignment: .bottomTrailing) {
            Menu {
                actions
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tint?.text ?? AppColor.Text.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More")
            // At the panel's bottom-right corner, left of the artwork.
            .padding(.trailing, ForYouCard.artworkWidth + 4)
            .padding(.bottom, 4)
        }
        .task(id: artworkSource) {
            let tint = await ArtworkTintLoader.tint(for: artworkSource)
            withAnimation(.easeInOut(duration: 0.3)) { loadedTint = tint }
        }
    }

    @ViewBuilder
    private var actions: some View {
        Button("Play", systemImage: "play.fill", action: onPlay)
        Button("Go to podcast", systemImage: "square.stack", action: onOpenPodcast)
    }
}
