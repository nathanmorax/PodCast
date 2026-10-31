//
//  PeekingCover.swift
//  Podcast
//

import SwiftUI

/// A followed show's cover in Home's row of shows. When the show has new
/// episodes, their artwork peeks out from behind it like cards in a deck:
/// once when the row appears (or a new one arrives) they rise and tilt,
/// then settle a little out, and stay like that until the show is opened.
/// With Reduce Motion they're simply shown settled.
struct PeekingCover: View {

    let podcast: Podcast
    /// The show's new episodes, newest first (empty: just the cover).
    let newEpisodes: [Episode]
    let side: CGFloat
    let cornerRadius: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// True for a moment while the cards jump out.
    @State private var isRaised = false

    /// The cards behind, back to front (at most two).
    private var cards: [Episode] {
        Array(newEpisodes.prefix(NewEpisodeMarks.maxPeeking).reversed())
    }

    var body: some View {
        ZStack {
            ForEach(Array(cards.enumerated()), id: \.element.streamUrl) { index, episode in
                card(episode, depth: cards.count - index)
            }

            Color.clear
                .frame(width: side, height: side)
                .overlay { ZoomSourceImage(podcast: podcast, cornerRadius: cornerRadius) }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(color: .black.opacity(newEpisodes.isEmpty ? 0 : 0.18), radius: 5, y: 3)
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
        // Seen (its page was opened): the cards slip back behind it.
        .animation(AppAnimation.listChange, value: newEpisodes.count)
        // Plays when it shows up, and again when the count grows.
        .task(id: newEpisodes.count) {
            guard !newEpisodes.isEmpty, !reduceMotion else { return }
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.spring(duration: 0.45, bounce: 0.45)) { isRaised = true }
            try? await Task.sleep(for: .milliseconds(900))
            withAnimation(.spring(duration: 0.6, bounce: 0.25)) { isRaised = false }
        }
    }

    /// depth 1 = right behind the cover, 2 = the one behind that.
    private func card(_ episode: Episode, depth: Int) -> some View {
        let lift: CGFloat = isRaised ? (depth == 1 ? 14 : 9) : (depth == 1 ? 7 : 4)
        let tilt: Double = isRaised ? (depth == 1 ? -7 : 6) : (depth == 1 ? -4 : 3)
        return Color.clear
            .frame(width: side, height: side)
            .overlay {
                PodcastImage(
                    source: episode.imageUrl?.isEmpty == false ? episode.imageUrl : podcast.artworkUrl600,
                    contentMode: .fill
                )
            }
            // Darker the further back, so the deck reads.
            .overlay { Color.black.opacity(depth == 1 ? 0.12 : 0.24) }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .rotationEffect(.degrees(tilt), anchor: .bottom)
            .offset(y: -lift)
    }
}
