//
//  EpisodeHeaderView.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//

import SwiftUI

// MARK: - Style Constants

private enum HeaderStyle {
    static let coverSide: CGFloat = 240
    static let coverCornerRadius: CGFloat = 16
    static let horizontalPadding: CGFloat = 24
    static let topPadding: CGFloat = 12
    static let nameTopPadding: CGFloat = 22
}

/// The top of a podcast's page, like Apple Podcasts: painted with the
/// artwork's color, the cover centered with a soft shadow, the name in
/// serif, its author, Follow, then Listen · ⓘ · share.
struct EpisodeHeaderView: View {

    let podcast: Podcast
    var isFavorite: Bool = false
    var podcastDescription: String?
    var isLoadingDescription: Bool = false
    /// The artwork's color; nil while it's being read (a neutral gray then).
    var tint: ArtworkTint?
    let actions: EpisodeHeaderActions

    /// Scrolled this far, the podcast's name has gone under the navigation
    /// bar: EpisodesController then shows it there.
    static let nameScrollsAwayAt: CGFloat =
        HeaderStyle.topPadding + HeaderStyle.coverSide + HeaderStyle.nameTopPadding + 44

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                heroSection
                followButton
                actionsRow
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 28)
            .background { tintedBackground }

            episodesCaption
        }
    }

    // MARK: - Colors

    private var backgroundTop: Color { tint?.color ?? AppColor.Surface.muted }
    private var backgroundBottom: Color { tint?.deeper ?? AppColor.Surface.muted }
    private var textColor: Color { tint?.text ?? AppColor.Text.primary }
    private var secondaryTextColor: Color { tint?.secondaryText ?? AppColor.Text.secondary }

    /// The color goes on above the header too (under the navigation bar and
    /// when the page is pulled down), so the top never shows a seam.
    private var tintedBackground: some View {
        VStack(spacing: 0) {
            backgroundTop.frame(height: 1000)
            LinearGradient(colors: [backgroundTop, backgroundBottom], startPoint: .top, endPoint: .bottom)
        }
        .padding(.top, -1000)
        .animation(.easeInOut(duration: 0.35), value: tint)
    }

    // MARK: - Hero

    private var artworkURL: String? {
        podcast.artworkURL?.absoluteString ?? podcast.artworkUrl600
    }

    private var heroSection: some View {
        VStack(spacing: 0) {
            PodcastImage(source: artworkURL, contentMode: .fill)
                .frame(width: HeaderStyle.coverSide, height: HeaderStyle.coverSide)
                .clipShape(RoundedRectangle(cornerRadius: HeaderStyle.coverCornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                // Editorial: the name in serif, like a magazine cover.
                Text(podcast.trackName ?? "")
                    .font(AppFont.display)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                if !heroCaption.isEmpty {
                    Text(heroCaption)
                        .overlineStyle(color: secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
            }
            .padding(.top, HeaderStyle.nameTopPadding)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, HeaderStyle.horizontalPadding)
        .padding(.top, HeaderStyle.topPadding)
    }

    /// "THE NEW YORK TIMES · NEWS" under the name.
    private var heroCaption: String {
        [podcast.artistName, podcast.primaryGenreName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    // MARK: - Follow

    /// Outlined, under the name. Followed podcasts live in Library.
    private var followButton: some View {
        Button {
            actions.send(.follow)
        } label: {
            Label(
                isFavorite ? "Following" : "Follow",
                systemImage: isFavorite ? "checkmark" : "plus"
            )
            .font(AppFont.button)
            .foregroundStyle(textColor)
            .contentTransition(.symbolEffect(.replace))
            .padding(.horizontal, 22)
            .frame(minHeight: 44)
            .overlay {
                Capsule().strokeBorder(textColor.opacity(0.55), lineWidth: 1.5)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: isFavorite)
        .padding(.top, 16)
    }

    // MARK: - Actions

    /// Listen (newest episode), the podcast's info, and share. The
    /// description isn't shown here: it's in the ⓘ sheet.
    private var actionsRow: some View {
        HStack(spacing: 10) {
            Button {
                actions.send(.play)
            } label: {
                Label("Listen to podcast", systemImage: "play.fill")
                    .font(AppFont.button)
                    // The pill takes the text's color, the label the
                    // background's: the same contrast, reversed.
                    .foregroundStyle(tint?.color ?? AppColor.Text.inverse)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Capsule().fill(textColor))
            }
            .buttonStyle(.plain)

            Button {
                actions.send(.about)
            } label: {
                roundIcon("info.circle")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About this podcast")

            if let shareURL {
                ShareLink(item: shareURL, subject: Text(podcast.trackName ?? "")) {
                    roundIcon("square.and.arrow.up")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share")
            }
        }
        .padding(.horizontal, HeaderStyle.horizontalPadding)
        .padding(.top, 22)
    }

    private func roundIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(textColor)
            .frame(width: 50, height: 50)
            .background(Circle().fill(textColor.opacity(0.16)))
    }

    /// The podcast on Apple Podcasts (opens in any app or browser).
    private var shareURL: URL? {
        URL(string: "https://podcasts.apple.com/podcast/id\(podcast.trackId)")
    }

    // MARK: - List title

    @ViewBuilder
    private var episodesCaption: some View {
        if let count = podcast.trackCount {
            Text("\(count) episodes")
                .overlineStyle()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, HeaderStyle.horizontalPadding)
                .padding(.top, 22)
                .padding(.bottom, 4)
        }
    }
}

#Preview("Tinted") {
    ScrollView {
        EpisodeHeaderView(
            podcast: .mock,
            isFavorite: true,
            tint: ArtworkTint(red: 0.62, green: 0.58, blue: 0.86),
            actions: EpisodeHeaderActions()
        )
    }
    .background(AppColor.screenBackground)
}

#Preview("Light artwork") {
    ScrollView {
        EpisodeHeaderView(
            podcast: .mock,
            tint: ArtworkTint(red: 0.93, green: 0.86, blue: 0.62),
            actions: EpisodeHeaderActions()
        )
    }
    .background(AppColor.screenBackground)
}

#Preview("Loading color") {
    ScrollView {
        EpisodeHeaderView(podcast: .mock, actions: EpisodeHeaderActions())
    }
    .background(AppColor.screenBackground)
}
