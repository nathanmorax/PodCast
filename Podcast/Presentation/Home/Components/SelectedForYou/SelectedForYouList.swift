//
//  SelectedForYouList.swift
//  Podcast
//

import SwiftUI

/// "Selected for you": discovery from your interests, laid out like a
/// magazine's recommendations. Each episode: its title in serif, a line of
/// what it's about next to a small cover, the show and its genre, and
/// "🎧 Listen · 30 min". A hairline between them.
struct SelectedForYouList: View {

    let items: [PodcastEpisode]
    let onOpen: (PodcastEpisode) -> Void
    let onPlay: (Episode) -> Void
    let onOpenPodcast: (Podcast) -> Void

    /// How many it lists (the row of For you brings up to eight).
    static let limit = 5

    @Environment(\.playerManager) private var playerManager

    private var shown: [PodcastEpisode] { Array(items.prefix(Self.limit)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            LibrarySectionHeader(title: "Selected for you", subtitle: "Based on your interests")

            VStack(spacing: 0) {
                ForEach(shown) { item in
                    ZoomSourceHost(id: .episode(item.episode.streamUrl, section: .forYou)) {
                        SelectedEpisodeRow(
                            item: item,
                            isPlaying: playerManager.currentEpisode?.streamUrl == item.episode.streamUrl
                                && playerManager.viewModel.isPlaying,
                            onOpen: { onOpen(item) },
                            onPlay: { onPlay(item.episode) },
                            onOpenPodcast: { onOpenPodcast(item.podcast) }
                        )
                    }
                    if item.id != shown.last?.id {
                        Divider()
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}

/// One recommendation. The texts and the cover open the episode; the
/// Listen capsule plays it.
private struct SelectedEpisodeRow: View {

    let item: PodcastEpisode
    let isPlaying: Bool
    let onOpen: () -> Void
    let onPlay: () -> Void
    let onOpenPodcast: () -> Void

    private var artwork: String? {
        if let image = item.episode.imageUrl, !image.isEmpty { return image }
        return item.podcast.artworkUrl600
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(item.episode.title)
                        .font(.system(.title2, design: .serif))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    HStack(alignment: .top, spacing: 16) {
                        Text(item.episode.description)
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(AppColor.Text.secondary)
                            .lineSpacing(3)
                            .lineLimit(4)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .topLeading)

                        RowArtwork(side: 96) {
                            PodcastImage(source: artwork, contentMode: .fill)
                        }
                    }

                    Text(showLine)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the episode")

            ListenCapsuleButton(
                isPlaying: isPlaying,
                duration: item.episode.durationDisplayText,
                action: onPlay
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .contextMenu {
            Button("Play", systemImage: "play.fill", action: onPlay)
            Button("Go to podcast", systemImage: "square.stack", action: onOpenPodcast)
        }
    }

    /// "Field Notes · Science".
    private var showLine: String {
        [item.podcast.trackName, item.podcast.primaryGenreName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
