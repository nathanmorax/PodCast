//
//  SearchExploreView.swift
//  Podcast
//

import SwiftUI

/// What Search shows before you type: the podcasts opened from Search
/// recently, then "Explore": every category as a grey card with its three
/// top covers, in two rows you slide sideways.
struct SearchExploreView: View {

    let onOpenPodcast: (Podcast) -> Void
    let onSelectGenre: (Genre) -> Void

    @Environment(\.recentSearches) private var recentSearches
    @Environment(\.interestsManager) private var interests
    /// Owned by the view: the covers stay while Search lives.
    @State private var genreCovers = GenreCoversViewModel()

    /// How many recent podcasts show (the rest are kept, not shown).
    static let recentLimit = 4

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if !recentSearches.items.isEmpty {
                    recentSection
                        .transition(.sectionReveal)
                }
                exploreSection
            }
            .padding(.top, 8)
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

    // MARK: - Explore

    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SearchSectionHeader(title: "Explore")
                .padding(.horizontal, 20)

            GenreGrid(
                genres: Genre.explore(interests: interests.genres),
                covers: genreCovers,
                onSelect: onSelectGenre
            )
        }
    }
}

// MARK: - Grid

/// Two rows of category cards that slide together.
private struct GenreGrid: View {

    let genres: [Genre]
    let covers: GenreCoversViewModel
    let onSelect: (Genre) -> Void

    private let rows = [
        GridItem(.fixed(GenreCard.height), spacing: 18),
        GridItem(.fixed(GenreCard.height))
    ]

    var body: some View {
        ScrollView(.horizontal) {
            LazyHGrid(rows: rows, spacing: 12) {
                ForEach(genres, id: \.id) { genre in
                    Button {
                        onSelect(genre)
                    } label: {
                        GenreCard(genre: genre, coverURLs: covers.coverURLs(for: genre))
                    }
                    .buttonStyle(.plain)
                    // Only cards on screen ask for their covers.
                    .task { await covers.load(genre) }
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}
