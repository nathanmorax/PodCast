//
//  EpisodeResultRow.swift
//  Podcast
//

import SwiftUI

/// An episode found by Search, read like an article: "SHOW · 2 DAYS AGO ·
/// 24 MIN" in violet, the title in serif, and its first sentence as a small
/// quote. Its cover on the right.
struct EpisodeResultRow: View {

    let result: EpisodeSearchResult

    private var episode: Episode { result.episode }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Text(meta)
                        .font(AppFont.captionStrong)
                        .textCase(.uppercase)
                        .foregroundStyle(AppColor.Accent.strong)
                        .lineLimit(1)
                    DownloadedBadge(episode: episode)
                }

                Text(episode.title)
                    .font(AppFont.itemTitle)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)

                if let line {
                    HStack(alignment: .top, spacing: 6) {
                        Text(verbatim: "“")
                            .font(.system(size: 24, design: .serif))
                            .foregroundStyle(AppColor.Accent.soft)
                            .frame(height: 18, alignment: .top)
                            .accessibilityHidden(true)
                        Text(line)
                            .font(AppFont.quoteSmall)
                            .foregroundStyle(AppColor.Text.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            PodcastImage(source: episode.imageUrl)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .accessibilityHidden(true)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// "Show · 2 days ago · 24 min" (parts that are missing are left out).
    private var meta: String {
        var parts = [result.podcastName]
        if episode.pubDate != .distantPast {
            parts.append(episode.pubDate.formatted(.relative(presentation: .named, unitsStyle: .wide)))
        }
        if episode.durationSeconds != nil {
            parts.append(episode.durationDisplayText)
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// The first sentence of the description, or the start of it.
    private var line: String? {
        let notes = EpisodeNotes(episode.description)
        let text = notes.quote ?? notes.rest
        return text.isEmpty ? nil : text
    }
}
