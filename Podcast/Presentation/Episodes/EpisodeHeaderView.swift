//
//  EpisodeHeaderView.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//

import SwiftUI

// MARK: - Style Constants

private enum HeaderStyle {
    static let artworkSize: CGFloat = 260
    static let artworkCornerRadius: CGFloat = 12
    static let heroHeight: CGFloat = 420
    static let horizontalPadding: CGFloat = 24
    static let collapsedLineLimit = 2
}

struct EpisodeHeaderView: View {
    
    let podcast: Podcast
    var isFavorite: Bool = false
    var podcastDescription: String?
    var isLoadingDescription: Bool = false
    let actions: EpisodeHeaderActions
    /// Pull-down distance from the list (nil in previews).
    var stretch: HeaderStretch?
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroSection
            actionsRow
            episodesCaption
        }
    }

    // MARK: - Hero
    

    private var artworkURL: String? {
        podcast.artworkURL?.absoluteString ?? podcast.artworkUrl600
    }

    /// The cover, edge to edge and under the status bar. It fades into the
    /// page at the bottom, where the podcast's name sits.
    ///
    /// Fixed height (the header measures itself). Pulling the list down makes
    /// only the image taller, anchored at the bottom, so it grows upward into
    /// the gap without changing the header's size.
    private var heroSection: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: HeaderStyle.heroHeight)
            .background(alignment: .bottom) {
                PodcastImage(source: artworkURL, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: HeaderStyle.heroHeight + (stretch?.pull ?? 0))
                    .clipped()
            }
            // Keeps the status bar and the back button readable on any cover.
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color(.systemBackground).opacity(0.55), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 130)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, Color(.systemBackground)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 190)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    if !heroCaption.isEmpty {
                        Text(heroCaption)
                            .font(AppFont.overline)
                            .textCase(.uppercase)
                            .foregroundStyle(AppColor.Text.secondary)
                            .lineLimit(1)
                    }
                    Text(podcast.trackName ?? "")
                        .font(AppFont.hero)
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, HeaderStyle.horizontalPadding)
                .padding(.bottom, 4)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
    }
    
    /// "RAÍZ PROFUNDA · CIENCIA" over the name.
    private var heroCaption: String {
        [podcast.artistName, podcast.primaryGenreName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
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
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Capsule().fill(AppColor.Accent.strong))
            }
            .buttonStyle(.plain)

            // Follow: + while not following, ✓ (filled violet) once followed.
            // Followed podcasts live in Library → "Following" and in Home.
            Button {
                actions.send(.follow)
            } label: {
                roundIcon(isFavorite ? "checkmark" : "plus", isOn: isFavorite)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: isFavorite)
            .accessibilityLabel(isFavorite ? Text("Unfollow") : Text("Follow"))

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
        .padding(.top, 18)
    }

    private func roundIcon(_ name: String, isOn: Bool = false) -> some View {
        Image(systemName: name)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(isOn ? AppColor.Text.inverse : AppColor.Accent.strong)
            .frame(width: 50, height: 50)
            .background(Circle().fill(isOn ? AppColor.Accent.strong : AppColor.Accent.wash))
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
                .font(AppFont.overline)
                .textCase(.uppercase)
                .tracking(0.4)
                .foregroundStyle(AppColor.Text.secondary)
                .padding(.horizontal, HeaderStyle.horizontalPadding)
                .padding(.top, 26)
                .padding(.bottom, 4)
        }
    }
}
