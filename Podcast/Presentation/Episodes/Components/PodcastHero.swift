//
//  PodcastHero.swift
//  Podcast
//

import SwiftUI

/// The top of a podcast's page: a soft wash of the cover's color fading
/// into the page, the cover rounded in the middle, then centered the name
/// in bold, who makes it in the accent, and "Science · Weekly · 214
/// episodes".
struct PodcastHero: View {

    let podcast: Podcast
    let cadence: ShowCadence?

    static let coverSide: CGFloat = 210

    /// The cover's color; read once it loads (cached after that).
    @State private var loadedTint: ArtworkTint?

    private var tint: ArtworkTint? {
        loadedTint ?? ArtworkTintLoader.cachedTint(for: podcast.artworkUrl600)
    }

    private var artworkURL: String? {
        podcast.artworkURL?.absoluteString ?? podcast.artworkUrl600
    }

    var body: some View {
        VStack(spacing: 0) {
            PodcastImage(source: artworkURL, contentMode: .fill)
                .frame(width: Self.coverSide, height: Self.coverSide)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 18, y: 10)
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(podcast.trackName ?? "")
                    .font(.title.weight(.bold))
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                if let host = podcast.artistName, !host.isEmpty {
                    Text(host)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColor.Accent.strong)
                        .lineLimit(1)
                }
                if !details.isEmpty {
                    Text(details)
                        .font(.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.top, 20)
            .padding(.horizontal, 24)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity)
        // Room for the status and navigation bars, which float over the wash.
        .padding(.top, 110)
        .background(alignment: .top) {
            ArtworkWash(color: tint?.color, height: 340)
        }
        .task(id: podcast.artworkUrl600) {
            guard loadedTint == nil else { return }
            let tint = await ArtworkTintLoader.tint(for: podcast.artworkUrl600)
            withAnimation(AppAnimation.stateChange) { loadedTint = tint }
        }
    }

    /// "Science · Weekly · 214 episodes": what's known of it.
    private var details: String {
        var parts: [String] = []
        if let genre = podcast.genreName {
            parts.append(genre)
        }
        if let cadence {
            parts.append(String(localized: cadence.title))
        }
        if let count = podcast.trackCount {
            parts.append(String(localized: "\(count) episodes"))
        }
        return parts.joined(separator: " · ")
    }
}
