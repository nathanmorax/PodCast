//
//  ForYouEpisodesRow.swift
//  Podcast
//

import SwiftUI

/// Big covers with the episode inside: "7 hours ago · 25 min" and its title.
/// Tap opens the episode full screen; holding it offers Play and Go to podcast.
struct ForYouEpisodesRow: View {

    let items: [ForYouViewModel.Item]
    let onOpen: (ForYouViewModel.Item) -> Void
    let onPlay: (Episode) -> Void
    let onOpenPodcast: (Podcast) -> Void

    private static let side: CGFloat = 180

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(items) { item in
                    Button {
                        onOpen(item)
                    } label: {
                        EpisodeCover(item: item, side: Self.side)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Play", systemImage: "play.fill") {
                            onPlay(item.episode)
                        }
                        Button("Go to podcast", systemImage: "square.stack") {
                            onOpenPodcast(item.podcast)
                        }
                    }
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}

/// One episode: its cover with "7 hours ago · 25 min" and the title inside.
private struct EpisodeCover: View {

    let item: ForYouViewModel.Item
    let side: CGFloat

    var body: some View {
        Color.clear
            .frame(width: side, height: side)
            .overlay { PodcastImage(source: item.episode.imageUrl ?? item.podcast.artworkUrl600) }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 3) {
                    // "7 hours ago · 25 min"
                    HStack(spacing: 0) {
                        Text(item.episode.pubDate, format: .relative(presentation: .numeric, unitsStyle: .wide))
                        Text(verbatim: " · \(item.episode.durationDisplayText)")
                    }
                    .font(AppFont.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
                    Text(item.episode.title)
                        .font(AppFont.label)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                // The fade keeps the text readable on any artwork.
                .background(
                    LinearGradient(colors: [.clear, .black.opacity(0.75)],
                                   startPoint: .top, endPoint: .bottom)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: LibraryCover.cornerRadius, style: .continuous))
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the episode")
    }
}

#Preview {
    ForYouEpisodesRow(
        items: Episode.mocks.map { ForYouViewModel.Item(podcast: .mock, episode: $0) },
        onOpen: { _ in },
        onPlay: { _ in },
        onOpenPodcast: { _ in }
    )
}
