//
//  EpisodeHero.swift
//  Podcast
//

import SwiftUI

/// The top of the episode page: the artwork edge to edge, under the status
/// bar and the clear navigation bar (pinned when pulled down), darker at
/// the bottom; over it the show in mustard capitals, the title in tall
/// capitals and "Science · 28 Oct 2026 · 48 min", in white.
struct EpisodeHero: View {

    let episode: Episode
    let showName: String?
    let genre: String?
    let pull: HeaderPull

    static let height: CGFloat = 440

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: Self.height)
            .background(alignment: .top) {
                PinnedCover(source: episode.imageUrl, height: Self.height, pull: pull)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.black.opacity(0), .black.opacity(0.85)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 280)
                .accessibilityHidden(true)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(showName ?? episode.author)
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .tracking(1.2)
                        .foregroundStyle(AppColor.Accent.soft)
                        .lineLimit(1)
                    Text(episode.title)
                        .font(AppFont.feedHero)
                        .textCase(.uppercase)
                        .lineLimit(4)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 4) {
                        if let genre {
                            Text(genre)
                            Text(verbatim: "·")
                        }
                        Text(episode.pubDate, format: .dateTime.day().month(.abbreviated).year())
                        Text(verbatim: "·")
                        Text(episode.durationDisplayText)
                    }
                    .font(.footnote)
                    .opacity(0.85)
                    .lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
    }
}
