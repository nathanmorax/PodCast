//
//  FeedEpisodeCard.swift
//  Podcast
//

import SwiftUI

/// An episode in Home's feed: the artwork filling a wide card and, at its
/// bottom left, a label (NEW, SHORT LISTEN…), the title in tall capitals
/// and the show. Tapping opens the episode; holding it offers Play and Go
/// to podcast.
struct FeedEpisodeCard: View {

    let item: PodcastEpisode
    let tag: FeedTag?
    let onOpen: () -> Void
    let onPlay: () -> Void
    let onOpenPodcast: () -> Void

    static let minHeight: CGFloat = 250

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 6) {
                if let tag {
                    FeedTagLabel(tag: tag)
                        .padding(.bottom, 2)
                }
                Text(item.episode.title)
                    .font(AppFont.feedTitle)
                    .textCase(.uppercase)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                FeedMetaLine(
                    show: item.showName,
                    details: [item.podcast.primaryGenreName ?? "", item.episode.durationDisplayText]
                )
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, minHeight: Self.minHeight, alignment: .bottomLeading)
            .background { FeedArtworkBackground(source: item.feedArtwork) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the episode")
        .contextMenu {
            Button("Play", systemImage: "play.fill", action: onPlay)
            Button("Go to podcast", systemImage: "square.stack", action: onOpenPodcast)
        }
    }
}
