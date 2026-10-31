//
//  MoreFromShowSection.swift
//  Podcast
//

import SwiftUI

/// "More from Field Notes": the show's other latest episodes, in the same
/// rows as Home and the show's page (▶, how far along, save, ⋮). Tapping a
/// row opens that episode.
struct MoreFromShowSection: View {

    let showName: String
    /// The show's cover, for episodes without their own.
    let showArtwork: String?
    let episodes: [Episode]
    let onOpen: (Episode) -> Void

    @Environment(\.recentlyPlayed) private var recentlyPlayed

    var body: some View {
        let played = Dictionary(recentlyPlayed.items.map { ($0.id, $0) }) { first, _ in first }

        VStack(alignment: .leading, spacing: 0) {
            EpisodeSectionTitle(title: "More from \(showName)")
            ForEach(episodes, id: \.streamUrl) { episode in
                EpisodeListRow(
                    episode: episode,
                    artwork: (episode.imageUrl ?? "").isEmpty ? showArtwork : episode.imageUrl,
                    played: played[episode.streamUrl],
                    zoomSection: .show
                ) { onOpen(episode) }
                if episode.streamUrl != episodes.last?.streamUrl {
                    Divider()
                }
            }
        }
    }
}
