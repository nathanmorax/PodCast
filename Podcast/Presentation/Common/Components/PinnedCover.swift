//
//  PinnedCover.swift
//  Podcast
//

import SwiftUI

/// A full-width cover at a fixed size (podcast page, episode page). While
/// the list is pulled past the top it moves up by the same distance, so it
/// stays pinned under the status bar. No zoom.
struct PinnedCover: View {
    let source: String?
    let height: CGFloat
    let pull: HeaderPull?

    var body: some View {
        PodcastImage(source: source, contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            // Keeps the status bar and the back button readable on any cover.
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color(.systemBackground).opacity(0.55), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 130)
            }
            .offset(y: -(pull?.distance ?? 0))
    }
}
