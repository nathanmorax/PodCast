//
//  EpisodeSearchItem+Domain.swift
//  Podcast
//

import Foundation

extension EpisodeSearchItem {

    /// Nil when there's nothing to play or no title.
    func toDomain() -> EpisodeSearchResult? {
        guard let title = trackName, !title.isEmpty,
              let streamUrl = episodeUrl, !streamUrl.isEmpty else { return nil }

        let notes = description?.plainTextFromHTML()
        let summary = (shortDescription?.isEmpty == false ? shortDescription : nil)?.strippingHTML()
            ?? notes
            ?? ""
        let episode = Episode(
            title: title,
            author: artistName ?? collectionName ?? "",
            pubDate: releaseDate.flatMap { try? Date($0, strategy: .iso8601) } ?? .distantPast,
            description: summary,
            durationSeconds: trackTimeMillis.map { TimeInterval($0) / 1000 },
            streamUrl: streamUrl,
            imageUrl: artworkUrl600,
            showNotes: notes
        )
        return EpisodeSearchResult(episode: episode, podcastName: collectionName ?? "")
    }
}
