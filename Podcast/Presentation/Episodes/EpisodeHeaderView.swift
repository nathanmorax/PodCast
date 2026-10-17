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
            aboutText
            listenButton
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
                            .font(.system(size: 13, weight: .bold))
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(podcast.trackName ?? "")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(.primary)
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

    // MARK: - About (two lines + ⓘ)

    /// Always two lines tall (even while loading), so the header never
    /// changes height. The full text opens from the ⓘ.
    private var aboutText: some View {
        let description = podcastDescription ?? ""
        let shown = isLoadingDescription ? String(localized: "Loading description…") : description
        return HStack(alignment: .top, spacing: 8) {
            Text(shown)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .lineLimit(2, reservesSpace: true)
                .redacted(reason: isLoadingDescription ? .placeholder : [])
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                actions.send(.about)
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(AppColor.lavenderInk)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(description.isEmpty)
            .opacity(description.isEmpty ? 0.3 : 1)
            .padding(.top, -10)
            .accessibilityLabel("About this podcast")
        }
        .padding(.leading, HeaderStyle.horizontalPadding)
        .padding(.trailing, HeaderStyle.horizontalPadding - 12)
        .padding(.top, 14)
    }

    // MARK: - Listen

    /// The only action: plays the newest episode.
    private var listenButton: some View {
        Button {
            actions.send(.play)
        } label: {
            Label("Listen to podcast", systemImage: "play.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Capsule().fill(AppColor.ink))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, HeaderStyle.horizontalPadding)
        .padding(.top, 18)
    }

    // MARK: - List title

    @ViewBuilder
    private var episodesCaption: some View {
        if let count = podcast.trackCount {
            Text("\(count) episodes")
                .font(.system(size: 13, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.4)
                .foregroundStyle(.secondary)
                .padding(.horizontal, HeaderStyle.horizontalPadding)
                .padding(.top, 26)
                .padding(.bottom, 4)
        }
    }
}
