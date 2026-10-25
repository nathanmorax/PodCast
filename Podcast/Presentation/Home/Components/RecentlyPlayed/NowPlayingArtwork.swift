//
//  NowPlayingArtwork.swift
//  Podcast
//

import SwiftUI

/// While an episode plays, its artwork breathes: a slow zoom and drift, and
/// a small frosted "Playing" badge with a moving waveform. With Reduce
/// Motion the image stays still (the badge and its waveform stay).
struct NowPlayingDrift: ViewModifier {

    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isActive && !reduceMotion {
            content
                .phaseAnimator([false, true]) { view, zoomed in
                    view
                        .scaleEffect(zoomed ? 1.08 : 1.0)
                        .offset(x: zoomed ? -6 : 0, y: zoomed ? -4 : 0)
                } animation: { _ in
                    .easeInOut(duration: 7)
                }
        } else {
            content
        }
    }
}

/// ≋ Playing, frosted, over the artwork's bottom-left corner.
struct NowPlayingBadge: View {

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "waveform")
                .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing)
            Text("Playing")
        }
        .font(AppFont.captionStrong)
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(.ultraThinMaterial, in: .capsule)
        // A dark frost reads on light and dark artwork alike.
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// The slow zoom and drift of an artwork whose episode is playing.
    func nowPlayingDrift(_ isActive: Bool) -> some View {
        modifier(NowPlayingDrift(isActive: isActive))
    }
}
