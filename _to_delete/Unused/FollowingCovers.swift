//
//  FollowingCovers.swift
//  Podcast
//

import SwiftUI

/// The podcasts you follow: big covers only (VoiceOver reads the names).
struct FollowingCovers: View {

    let podcasts: [Podcast]
    let onOpen: (Podcast) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 12) {
                ForEach(podcasts, id: \.trackId) { podcast in
                    Button {
                        onOpen(podcast)
                    } label: {
                        Color.clear
                            .frame(width: 104, height: 104)
                            .overlay { PodcastImage(source: podcast.artworkUrl600) }
                            .clipShape(RoundedRectangle(cornerRadius: LibraryCover.cornerRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: podcast.trackName ?? ""))
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}
