//
//  PeekingCover.swift
//  Podcast
//

import SwiftUI

/// A followed show's cover in Home's row of shows. When the show has new
/// episodes, their artwork peeks out from behind it like cards in a deck,
/// a little out; every few seconds they rise and tilt, then settle again
/// (the one behind a beat later), until the show is opened. With Reduce
/// Motion they're simply shown settled.
struct PeekingCover: View {

    let podcast: Podcast
    /// The show's new episodes, newest first (empty: just the cover).
    let newEpisodes: [Episode]
    let side: CGFloat
    let cornerRadius: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
    }

    /// depth 1 = right behind the cover, 2 = the one behind that.
    @ViewBuilder
    private func card(_ episode: Episode, depth: Int) -> some View {
        let rest = PeekPose.rest(depth: depth)
        let face = Color.clear
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

        if reduceMotion {
            face
                .rotationEffect(.degrees(rest.tilt), anchor: .bottom)
                .offset(y: -rest.lift)
        } else {
            face.keyframeAnimator(initialValue: rest, repeating: true) { view, pose in
                view
                    .rotationEffect(.degrees(pose.tilt), anchor: .bottom)
                    .offset(y: -pose.lift)
            } keyframes: { _ in
                PeekPose.loop(depth: depth)
            }
        }
    }
}

/// Where a card behind the cover is: how far up, how tilted.
private struct PeekPose {
    var lift: CGFloat
    var tilt: Double

    static func rest(depth: Int) -> PeekPose {
        depth == 1 ? PeekPose(lift: 7, tilt: -4) : PeekPose(lift: 4, tilt: 3)
    }

    static func raised(depth: Int) -> PeekPose {
        depth == 1 ? PeekPose(lift: 14, tilt: -7) : PeekPose(lift: 9, tilt: 6)
    }

    /// One lap (3.2 s): rise with a bounce, hold, settle, rest. The card
    /// behind starts a beat later.
    @KeyframesBuilder<PeekPose>
    static func loop(depth: Int) -> some Keyframes<PeekPose> {
        let rest = rest(depth: depth)
        let raised = raised(depth: depth)
        let delay = depth == 1 ? 0.0 : 0.08
        KeyframeTrack(\.lift) {
            LinearKeyframe(rest.lift, duration: 0.4 + delay)
            SpringKeyframe(raised.lift, duration: 0.45, spring: .bouncy)
            LinearKeyframe(raised.lift, duration: 0.8)
            SpringKeyframe(rest.lift, duration: 0.55, spring: .smooth)
            LinearKeyframe(rest.lift, duration: 1.0 - delay)
        }
        KeyframeTrack(\.tilt) {
            LinearKeyframe(rest.tilt, duration: 0.4 + delay)
            SpringKeyframe(raised.tilt, duration: 0.45, spring: .bouncy)
            LinearKeyframe(raised.tilt, duration: 0.8)
            SpringKeyframe(rest.tilt, duration: 0.55, spring: .smooth)
            LinearKeyframe(rest.tilt, duration: 1.0 - delay)
        }
    }
}
