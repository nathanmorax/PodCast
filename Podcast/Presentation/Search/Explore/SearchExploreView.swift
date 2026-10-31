//
//  SearchExploreView.swift
//  Podcast
//
import SwiftUI

/// What Search shows before you type, like a magazine's contents page:
/// - "Shows like …": the cover of the show you followed last, full width
///   (opens its category);
/// - the podcasts opened from Search recently;
/// - "Browse": every category as a tile with its top shows' covers, two
///   per row, edge to edge (your interests first).
struct SearchExploreView: View {
    let onOpenPodcast: (Podcast) -> Void
    let onSelectGenre: (Genre) -> Void

    @Environment(\.recentSearches) private var recentSearches
    @Environment(\.interestsManager) private var interests
    @Environment(\.favoritesManager) private var favoritesManager

    /// How many recent podcasts show (the rest are kept, not shown).
    static let recentLimit = 4

    /// The show "Shows like …" is about: the last one followed that has a
    /// category.
    private var showsLikePick: (podcast: Podcast, genre: Genre)? {
        guard let podcast = favoritesManager.favorites.last(where: { $0.genreName != nil }),
              let name = podcast.genreName else { return nil }
        // A catalog category when it is one; otherwise the API's (the
        // ranking searches by name, so it works as is).
        return (podcast, podcast.catalogGenre ?? Genre(id: name, name: name))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let pick = showsLikePick {
                    ShowsLikeBanner(podcast: pick.podcast, genreName: pick.genre.name) {
                        onSelectGenre(pick.genre)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                if !recentSearches.items.isEmpty {
                    recentSection
                        .padding(.top, 22)
                        .transition(.sectionReveal)
                }
                browseSection
                    .padding(.top, 24)
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .animation(AppAnimation.listChange, value: recentSearches.items.map(\.trackId))
    }

    // MARK: - Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SearchSectionHeader(title: "Recent", actionTitle: "Clear") {
                withAnimation(AppAnimation.listChange) { recentSearches.clear() }
            }
            ForEach(recentSearches.items.prefix(Self.recentLimit), id: \.trackId) { podcast in
                RecentPodcastRow(
                    podcast: podcast,
                    onOpen: { onOpenPodcast(podcast) },
                    onRemove: {
                        withAnimation(AppAnimation.listChange) { recentSearches.remove(podcast) }
                    }
                )
                .overlay(alignment: .bottom) { Divider() }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Browse

    private var browseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SearchSectionHeader(title: "Browse")
                .padding(.horizontal, 20)
            GenreCoverGrid(
                genres: Genre.explore(interests: interests.genres),
                onSelect: onSelectGenre
            )
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Grid

/// The category tiles, two per row, rounded, with the page's margins. Each one
/// fetches its covers the first time it shows.
private struct GenreCoverGrid: View {
    let genres: [Genre]
    let onSelect: (Genre) -> Void

    @State private var covers = GenreCovers.shared

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(genres, id: \.id) { genre in
                Button {
                    onSelect(genre)
                } label: {
                    GenreCoverTile(genre: genre, covers: covers.artwork(for: genre))
                }
                .buttonStyle(.plain)
                .task { await covers.load(genre) }
            }
        }
    }
}
