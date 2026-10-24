//
//  ForYouCard.swift
//  Podcast
//

import SwiftUI

/// One "For you" episode, like Apple Podcasts' "Recommended For You": a
/// panel painted with the artwork's color (the podcast's small cover, its
/// name, the episode's title in serif, when and how long) next to the
/// episode's artwork, cut at the card's right edge.
///
/// Only draws: the color, tapping, the ••• menu and the zoom live in
/// ForYouRow.
struct ForYouCard: View {

    let item: PodcastEpisode
    /// The artwork's color; nil while it's being read (a neutral gray).
    let tint: ArtworkTint?

    static let height: CGFloat = 220
    static let cornerRadius: CGFloat = 8
    /// The artwork's width, as a fraction of the card's height.
    static let artworkRatio: CGFloat = 0.72
    static var artworkWidth: CGFloat { height * artworkRatio }

    /// The episode's own artwork; the podcast's when the feed has none.
    static func artworkSource(for item: PodcastEpisode) -> String? {
        if let image = item.episode.imageUrl, !image.isEmpty { return image }
        return item.podcast.artworkUrl600
    }

    var body: some View {
        HStack(spacing: 0) {
            infoPanel
            PodcastImage(source: Self.artworkSource(for: item), contentMode: .fill)
                .frame(width: Self.artworkWidth)
                .frame(maxHeight: .infinity)
                .clipped()
                .accessibilityHidden(true)
        }
        .frame(height: Self.height)
        .background { panelBackground }
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
    }

    // MARK: - Panel

    private var textColor: Color { tint?.text ?? AppColor.Text.primary }
    private var secondaryTextColor: Color { tint?.secondaryText ?? AppColor.Text.secondary }

    /// The artwork's color, a little lighter at the top-left, like light
    /// falling on it.
    private var panelBackground: some View {
        let base = tint?.color ?? AppColor.Surface.muted
        return base
            .overlay {
                RadialGradient(
                    colors: [.white.opacity(0.14), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 260
                )
            }
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [.clear, (tint?.deeper ?? base).opacity(0.9)],
                               startPoint: .center, endPoint: .bottom)
            }
    }

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                PodcastImage(source: item.podcast.artworkUrl600)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .accessibilityHidden(true)
                Text(item.podcast.trackName ?? "")
                    .overlineStyle(color: textColor)
                    .lineLimit(2)
            }

            Text(item.episode.title)
                .font(AppFont.cardHeadline)
                .foregroundStyle(textColor)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .padding(.top, 14)

            Spacer(minLength: 8)

            // "7 hours ago · 25 min"; the ••• goes to its right (ForYouRow).
            HStack(spacing: 0) {
                Text(item.episode.pubDate, format: .relative(presentation: .numeric, unitsStyle: .abbreviated))
                Text(verbatim: " · \(item.episode.durationDisplayText)")
            }
            .font(AppFont.caption)
            .foregroundStyle(secondaryTextColor)
            .lineLimit(1)
            .padding(.trailing, 36)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }

}
