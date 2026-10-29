//
//  PodcastHero.swift
//  Podcast
//

import SwiftUI

/// The top of a podcast's page, like a film's page: the cover edge to edge
/// under the clear navigation bar (it grows when pulled down), darker at
/// the bottom; over it the genre in mustard, the name in very tall
/// capitals and "By host · Weekly · 214 episodes", in white.
struct PodcastHero: View {

    let podcast: Podcast
    let cadence: ShowCadence?

    static let height: CGFloat = 420

    private var artworkURL: String? {
        podcast.artworkURL?.absoluteString ?? podcast.artworkUrl600
    }

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: Self.height)
            .background {
                PodcastImage(source: artworkURL, contentMode: .fill)
                    .visualEffect { content, proxy in
                        // Pulled down: it grows from the bottom edge.
                        let pull = max(0, proxy.frame(in: .scrollView).minY)
                        let scale = proxy.size.height > 0 ? 1 + pull / proxy.size.height : 1
                        return content.scaleEffect(scale, anchor: .bottom)
                    }
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.black.opacity(0), .black.opacity(0.85)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 260)
                .accessibilityHidden(true)
            }
            .overlay(alignment: .bottomLeading) { texts }
            .clipped()
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let genre = podcast.primaryGenreName, !genre.isEmpty {
                Text(genre)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(AppColor.Accent.soft)
            }
            Text(podcast.trackName ?? "")
                .font(.system(size: 56, weight: .bold).width(.compressed))
                .textCase(.uppercase)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)
            Text(byline)
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

    /// "By host · Weekly · 214 episodes": what's known of it.
    private var byline: String {
        var parts: [String] = []
        if let host = podcast.artistName, !host.isEmpty {
            parts.append(String(localized: "By \(host)"))
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
