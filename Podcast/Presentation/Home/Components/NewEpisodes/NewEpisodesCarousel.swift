//
//  NewEpisodesCarousel.swift
//  Podcast
//

import SwiftUI

/// Home's "New episodes": the newest episodes of the shows you follow (the
/// Library's New tab), one big card at a time, the next ones peeking at the sides and
/// a little smaller. Dots under it say where you are. "Show all" opens
/// the Library on its New tab.
struct NewEpisodesCarousel: View {

    let items: [PodcastEpisode]
    let onOpen: (PodcastEpisode) -> Void
    let onPlay: (Episode) -> Void
    let onOpenPodcast: (Podcast) -> Void
    let onShowAll: () -> Void

    /// At most this many cards (the rest are in Library › New); as many as
    /// PageDots draws.
    static let limit = 10

    @Environment(\.playerManager) private var playerManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentID: PodcastEpisode.ID?

    private var shown: [PodcastEpisode] { Array(items.prefix(Self.limit)) }

    private var currentIndex: Int {
        guard let currentID, let index = shown.firstIndex(where: { $0.id == currentID }) else { return 0 }
        return index
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LibrarySectionHeader(
                title: "New episodes",
                subtitle: "From the shows you follow",
                onShowAll: onShowAll
            )

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(shown) { item in
                        card(item)
                            .containerRelativeFrame(.horizontal) { width, _ in
                                min(width * 0.78, 340)
                            }
                            // The ones at the sides: a bit smaller and faded.
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity || reduceMotion ? 1 : 0.94)
                                    .opacity(phase.isIdentity ? 1 : 0.6)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentID)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .scrollIndicators(.hidden)

            if shown.count > 1 {
                PageDots(count: shown.count, current: currentIndex)
            }
        }
    }

    private func card(_ item: PodcastEpisode) -> some View {
        // Its own host, so the episode zooms out of the card and back.
        ZoomSourceHost(
            id: .episode(item.episode.streamUrl, section: .newEpisodes),
            cornerRadius: NewEpisodeCard.cornerRadius
        ) {
            NewEpisodeCard(
                item: item,
                isPlaying: playerManager.currentEpisode?.streamUrl == item.episode.streamUrl
                    && playerManager.viewModel.isPlaying,
                onOpen: { onOpen(item) },
                onPlay: { onPlay(item.episode) },
                onOpenPodcast: { onOpenPodcast(item.podcast) }
            )
        }
    }
}
