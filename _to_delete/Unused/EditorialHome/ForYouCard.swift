//
//  ForYouCard.swift
//  Podcast
//

import SwiftUI

/// One "For you" episode, like a magazine's audio stories: the artwork,
/// square, with ▶ (black, outlined in white) on its bottom-right corner;
/// under it the category in serif capitals, the title in bold, "By author"
/// and the length.
///
/// Only draws, in two pieces (ForYouCard.Artwork, ForYouCard.Texts), so
/// ForYouRow can make each one its own button with ▶ over the artwork.
/// Tapping, ▶, the menu and the zoom live in ForYouRow. (A namespace, not a
/// View: it has no body of its own.)
enum ForYouCard {

    static let cornerRadius: CGFloat = 6
    /// While the row loads (the card's real height comes from its width).
    static let placeholderHeight: CGFloat = 380

    /// The episode's own artwork; the podcast's when the feed has none.
    static func artworkSource(for item: PodcastEpisode) -> String? {
        if let image = item.episode.imageUrl, !image.isEmpty { return image }
        return item.podcast.artworkUrl600
    }

    /// The square artwork, with a hairline edge (light artwork doesn't
    /// melt into the page).
    struct Artwork: View {
        let item: PodcastEpisode

        var body: some View {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    PodcastImage(source: ForYouCard.artworkSource(for: item), contentMode: .fill)
                }
                .clipShape(RoundedRectangle(cornerRadius: ForYouCard.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: ForYouCard.cornerRadius, style: .continuous)
                        .strokeBorder(AppColor.Text.primary.opacity(0.12), lineWidth: 1)
                }
                .accessibilityHidden(true)
        }
    }

    /// Category, title, "By author", length. Each line keeps its space, so
    /// the cards side by side end at the same height.
    struct Texts: View {
        let item: PodcastEpisode

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.podcast.primaryGenreName ?? " ")
                    .font(.system(.subheadline, design: .serif))
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .foregroundStyle(AppColor.Status.critical)
                    .lineLimit(1)

                Text(item.episode.title)
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 2)

                Text(byline)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.episode.durationDisplayText)
                    DownloadedBadge(episode: item.episode)
                }
                .font(.subheadline)
                .foregroundStyle(AppColor.Text.secondary)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }

        private var byline: String {
            let author = item.podcast.artistName ?? item.episode.author
            return author.isEmpty ? " " : String(localized: "By \(author)")
        }
    }
}
