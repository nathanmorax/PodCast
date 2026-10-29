//
//  EpisodeOfTheDayCard.swift
//  Podcast
//

import SwiftUI

/// The feed's first card, like a film magazine's "Film of the day": the
/// artwork filling a tall card and, centered at the bottom, the label in
/// mustard, the title in tall capitals, the show, two lines of what it's
/// about and a white Listen.
///
/// The texts open the episode; Listen plays it in the mini player.
struct EpisodeOfTheDayCard: View {

    let item: PodcastEpisode
    let isPlaying: Bool
    let onOpen: () -> Void
    let onListen: () -> Void

    static let minHeight: CGFloat = 460

    var body: some View {
        VStack(spacing: 16) {
            Button(action: onOpen) {
                VStack(spacing: 8) {
                    Text("Episode of the day")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .foregroundStyle(AppColor.Accent.soft)

                    Text(item.episode.title)
                        .font(AppFont.feedHero)
                        .textCase(.uppercase)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)

                    FeedMetaLine(
                        show: item.showName,
                        details: [item.podcast.primaryGenreName ?? "", item.episode.durationDisplayText]
                    )

                    if !item.episode.description.isEmpty {
                        Text(item.episode.description)
                            .font(.subheadline)
                            .lineLimit(2)
                            .opacity(0.9)
                    }
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the episode")

            Button(action: onListen) {
                Label(isPlaying ? "Pause" : "Listen", systemImage: isPlaying ? "pause.fill" : "play.fill")
                    .font(.subheadline.weight(.bold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 22)
                    .frame(minHeight: 44)
                    .background(.white, in: .capsule)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity, minHeight: Self.minHeight)
        .background { FeedArtworkBackground(source: item.feedArtwork) }
    }
}
