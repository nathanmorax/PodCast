//
//  ForYouList.swift
//  Podcast
//

import SwiftUI

/// "For you", editorial, like a magazine's "Latest Podcasts": one episode
/// per row, the show in serif capitals, the title in bold, the date and
/// length; the artwork on the right with ▶ over its corner.
///
/// Tapping a row opens the episode (zooming out of its artwork); ▶ plays it
/// right away; holding a row offers Play and Go to podcast.
struct ForYouList: View {

    let items: [PodcastEpisode]
    let onOpen: (PodcastEpisode) -> Void
    let onPlay: (Episode) -> Void
    let onOpenPodcast: (Podcast) -> Void

    /// Rows shown.
    static let limit = 6

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 26) {
            ForEach(items.prefix(Self.limit)) { item in
                ForYouListRow(
                    item: item,
                    onOpen: { onOpen(item) },
                    onPlay: { onPlay(item.episode) },
                    onOpenPodcast: { onOpenPodcast(item.podcast) }
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

private struct ForYouListRow: View {

    let item: PodcastEpisode
    let onOpen: () -> Void
    let onPlay: () -> Void
    let onOpenPodcast: () -> Void

    private static let artworkSide: CGFloat = 96

    @Environment(\.playerManager) private var playerManager

    private var isPlaying: Bool {
        playerManager.currentEpisode?.streamUrl == item.episode.streamUrl && playerManager.viewModel.isPlaying
    }

    /// The episode's own artwork; the podcast's when the feed has none.
    private var artworkSource: String? {
        if let image = item.episode.imageUrl, !image.isEmpty { return image }
        return item.podcast.artworkUrl600
    }

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.podcast.trackName ?? "")
                        .seriesCapsStyle()
                        .lineLimit(1)
                    Text(item.episode.title)
                        .font(AppFont.listTitle)
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    // "October 23, 2026 · 56 min"
                    HStack(spacing: 0) {
                        Text(item.episode.pubDate, format: .dateTime.day().month(.wide).year())
                        Text(verbatim: " · \(item.episode.durationDisplayText)")
                    }
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Color.clear
                    .frame(width: Self.artworkSide, height: Self.artworkSide)
                    .overlay {
                        ZoomSourceImage(
                            id: .episode(item.episode.streamUrl, section: .forYou),
                            source: artworkSource,
                            cornerRadius: 2
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the episode")
        .contextMenu {
            Button("Play", systemImage: "play.fill", action: onPlay)
            Button("Go to podcast", systemImage: "square.stack", action: onOpenPodcast)
        }
        // Over the artwork's corner, outside the row's Button (a button in
        // a button's label wouldn't get its own tap).
        .overlay(alignment: .topTrailing) {
            Button(action: onPlay) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(.black))
                    .overlay { Circle().strokeBorder(.white.opacity(0.85), lineWidth: 1) }
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? Text("Pause") : Text("Play"))
            .offset(x: 2, y: Self.artworkSide - 44 + 2)
        }
    }
}
