//
//  YourShowsSection.swift
//  Podcast
//

import SwiftUI

/// "Your shows": the podcasts you follow, the most recently updated first,
/// each with its latest episodes in a row you slide sideways (like a
/// newspaper's shows page). The show's line says how often it publishes and
/// how many episodes are new since you last opened the Inbox.
struct YourShowsSection: View {

    let podcasts: [Podcast]
    let episodesByPodcast: [Int: [Episode]]
    /// Episodes after this count as new (the Inbox's last visit).
    let newSince: Date
    let onOpenPodcast: (Podcast) -> Void
    let onOpenEpisode: (Episode, Podcast) -> Void
    let onPlay: (Episode) -> Void
    let onShowAll: () -> Void

    /// Shows listed here; the rest are in Following.
    static let showLimit = 4
    /// Episodes in each show's row.
    static let episodeLimit = 6

    /// Shows with episodes, the one that published last first.
    private var shows: [Show] {
        podcasts
            .compactMap { podcast -> Show? in
                let episodes = (episodesByPodcast[podcast.trackId] ?? [])
                    .sorted { $0.pubDate > $1.pubDate }
                return episodes.isEmpty ? nil : Show(podcast: podcast, episodes: episodes)
            }
            .sorted { ($0.episodes.first?.pubDate ?? .distantPast) > ($1.episodes.first?.pubDate ?? .distantPast) }
            .prefix(Self.showLimit)
            .map { $0 }
    }

    private struct Show: Identifiable {
        let podcast: Podcast
        let episodes: [Episode]
        var id: Int { podcast.trackId }
    }

    var body: some View {
        let shows = self.shows
        if !shows.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                LibrarySectionHeader(
                    title: "Your shows",
                    onShowAll: podcasts.count > shows.count ? onShowAll : nil
                )

                VStack(alignment: .leading, spacing: 28) {
                    ForEach(shows) { show in
                        ShowBlock(
                            podcast: show.podcast,
                            episodes: show.episodes,
                            newSince: newSince,
                            onOpenPodcast: { onOpenPodcast(show.podcast) },
                            onOpenEpisode: { onOpenEpisode($0, show.podcast) },
                            onPlay: onPlay
                        )
                    }
                }
            }
        }
    }
}

/// One show: its line (cover, name ›, "EVERY WEEK · 2 NEW") and its latest
/// episodes.
private struct ShowBlock: View {

    let podcast: Podcast
    let episodes: [Episode]
    let newSince: Date
    let onOpenPodcast: () -> Void
    let onOpenEpisode: (Episode) -> Void
    let onPlay: (Episode) -> Void

    private var newCount: Int {
        episodes.lazy.filter { $0.pubDate > newSince }.count
    }

    /// "EVERY WEEK · 2 NEW", either part when the other is missing.
    private var caption: Text? {
        let cadence = ShowCadence(dates: episodes.map(\.pubDate)).map { Text($0.title) }
        let new = newCount > 0 ? Text("\(newCount) new") : nil
        switch (cadence, new) {
        case let (cadence?, new?): return Text("\(cadence) · \(new)")
        case let (cadence?, nil): return cadence
        case let (nil, new?): return new
        default: return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onOpenPodcast) {
                HStack(spacing: 14) {
                    RowArtwork(side: 56) {
                        PodcastImage(source: podcast.artworkUrl600, contentMode: .fill)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(podcast.trackName ?? "")
                                .font(.system(.title3, design: .serif, weight: .semibold))
                                .foregroundStyle(AppColor.Text.primary)
                                .lineLimit(1)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(AppColor.Text.secondary)
                                .accessibilityHidden(true)
                        }
                        if let caption {
                            caption.overlineStyle()
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the podcast")

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(episodes.prefix(YourShowsSection.episodeLimit), id: \.streamUrl) { episode in
                        ZoomSourceHost(
                            id: .episode(episode.streamUrl, section: .yourShows),
                            cornerRadius: RowArtwork<EmptyView>.cornerRadius
                        ) {
                            ShowEpisodeCard(
                                episode: episode,
                                fallbackArtwork: podcast.artworkUrl600,
                                isNew: episode.pubDate > newSince,
                                onOpen: { onOpenEpisode(episode) },
                                onPlay: { onPlay(episode) },
                                onOpenPodcast: onOpenPodcast
                            )
                        }
                        .frame(width: ShowEpisodeCard.width)
                    }
                }
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .scrollIndicators(.hidden)
        }
    }
}

/// An episode under its show: the cover (a dot when it's new), the title in
/// serif and "40 MIN" with its ••• menu.
private struct ShowEpisodeCard: View {

    let episode: Episode
    let fallbackArtwork: String?
    let isNew: Bool
    let onOpen: () -> Void
    let onPlay: () -> Void
    let onOpenPodcast: () -> Void

    static let width: CGFloat = 156

    private var artwork: String? {
        if let image = episode.imageUrl, !image.isEmpty { return image }
        return fallbackArtwork
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 10) {
                    RowArtwork(side: Self.width) {
                        PodcastImage(source: artwork, contentMode: .fill)
                    }
                    .overlay(alignment: .topLeading) {
                        if isNew {
                            Circle()
                                .fill(AppColor.Accent.soft)
                                .frame(width: 10, height: 10)
                                .overlay { Circle().strokeBorder(.white, lineWidth: 1.5) }
                                .padding(8)
                                .accessibilityHidden(true)
                        }
                    }

                    Text(episode.title)
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(3, reservesSpace: true)
                        .multilineTextAlignment(.leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityValue(isNew ? Text("New") : Text(verbatim: ""))
            .accessibilityHint("Opens the episode")

            HStack {
                Text(episode.durationDisplayText)
                    .overlineStyle()
                Spacer(minLength: 0)
                Menu {
                    Button("Play", systemImage: "play.fill", action: onPlay)
                    Button("Details", systemImage: "info.circle", action: onOpen)
                    Button("Go to podcast", systemImage: "square.stack", action: onOpenPodcast)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColor.Text.secondary)
                        .frame(width: 44, height: 32)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("More")
            }
        }
        .frame(width: Self.width, alignment: .leading)
    }
}
