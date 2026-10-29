//
//  SearchExploreView.swift
//  Podcast
//

import SwiftUI

/// What Search shows before you type: the podcasts opened from Search
/// recently, then "Explore": every category as a pastel card with its
/// symbol, two per row (your interests first).
struct SearchExploreView: View {

    let onOpenPodcast: (Podcast) -> Void
    let onSelectGenre: (Genre) -> Void

    @Environment(\.recentSearches) private var recentSearches
    @Environment(\.interestsManager) private var interests

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
                onSelect: onSelectGenre
            )
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Grid

/// The category cards, two per row.
private struct GenreGrid: View {

    let genres: [Genre]
    let onSelect: (Genre) -> Void

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
                    GenreCard(genre: genre)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
