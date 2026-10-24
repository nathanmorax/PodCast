//
//  RecentlyPlayedHero.swift
//  Podcast
//

import SwiftUI

/// One episode you played, big, like Apple Podcasts' episode cards (a page
/// of RecentlyPlayedCarousel), straight on the page:
/// - the show: its small cover, its name in serif, when you played it;
/// - the artwork filling the card's width (with how far you got as a
///   mustard line along its bottom);
/// - the title in serif, its short description;
/// - what's left ("23 MIN LEFT") and •••.
///
/// Tapping it resumes; ••• (or holding it) offers Resume, the details and
/// removing it. The details open zooming out of the artwork.
struct RecentlyPlayedHero: View {

    let item: RecentlyPlayed
    let onResume: () -> Void
    let onOpen: () -> Void
    let onRemove: () -> Void

    private static let showCoverSide: CGFloat = 52
    /// Width ÷ height of the big artwork (the square cover, cropped).
    private static let artworkRatio: CGFloat = 16 / 9
    private static let artworkCornerRadius: CGFloat = 10

    var body: some View {
        Button(action: onResume) {
            VStack(alignment: .leading, spacing: 0) {
                showHeader
                artwork
                    .padding(.top, 14)
                texts
                    .padding(.top, 14)
                footer
                    .padding(.top, 12)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Resumes the episode")
        .contextMenu { actions }
        // Over the card, not inside the Button's label: a Menu in a label
        // fights the Button for the tap.
        .overlay(alignment: .bottomTrailing) {
            Menu {
                actions
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppColor.Text.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More")
            .offset(x: 10, y: 12)
        }
    }

    @ViewBuilder
    private var actions: some View {
        Button("Resume", systemImage: "play.fill", action: onResume)
        Button("Episode details", systemImage: "text.alignleft", action: onOpen)
        Button("Remove from recently played", systemImage: "minus.circle", role: .destructive, action: onRemove)
    }

    // MARK: - The show

    /// Small cover, the name in serif, "2 HOURS AGO" under it.
    private var showHeader: some View {
        HStack(spacing: 14) {
            PodcastImage(source: item.artworkSource)
                .frame(width: Self.showCoverSide, height: Self.showCoverSide)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                // Always there (a blank line when the feed has no author):
                // every card in the carousel keeps the same height.
                Text(item.episode.author.isEmpty ? " " : item.episode.author)
                    .font(AppFont.itemTitle)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)

                Text(item.lastPlayedAt, format: .relative(presentation: .named))
                    .overlineStyle()
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Artwork

    /// The cover cropped to the card's width (the feeds only have square
    /// artwork), with the progress along its bottom. It's what the details
    /// zoom out of.
    private var artwork: some View {
        Color.clear
            .aspectRatio(Self.artworkRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay {
                ZoomSourceImage(
                    id: .episode(item.episode.streamUrl, section: .recentlyPlayed),
                    source: item.artworkSource,
                    cornerRadius: Self.artworkCornerRadius
                )
            }
            .overlay(alignment: .bottom) { progressLine }
            .clipShape(RoundedRectangle(cornerRadius: Self.artworkCornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }

    private var progressLine: some View {
        Rectangle()
            .fill(.white.opacity(0.25))
            .frame(height: 3)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(AppColor.Accent.soft)
                    .scaleEffect(x: min(max(item.progress, 0), 1), y: 1, anchor: .leading)
            }
    }

    // MARK: - Texts

    /// Space for two lines each, always: the cards side by side in the
    /// carousel keep the same height.
    private var texts: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.episode.title)
                .font(AppFont.cardHeadline)
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(2, reservesSpace: true)

            Text(item.episode.description.isEmpty ? " " : item.episode.description)
                .font(AppFont.cardDeck)
                .foregroundStyle(AppColor.Text.secondary)
                .lineLimit(2, reservesSpace: true)
        }
    }

    /// "23 MIN LEFT"; the ••• sits at its right (overlay).
    private var footer: some View {
        Text("\(item.minutesLeftText) left")
            .overlineStyle()
            .lineLimit(1)
            .frame(minHeight: 20, alignment: .leading)
    }
}
