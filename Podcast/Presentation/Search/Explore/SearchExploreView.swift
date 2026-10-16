//
//  SearchExploreView.swift
//  Podcast
//

import SwiftUI

/// What Search shows before you type: the podcasts you searched recently and
/// the categories to explore.
struct SearchExploreView: View {

    let genresViewModel: GenresViewModel
    let onOpenPodcast: (Podcast) -> Void
    let onSelectGenre: (Genre) -> Void

    @Environment(\.recentSearches) private var recentSearches

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if !recentSearches.items.isEmpty {
                    recentSection
                        .transition(.sectionReveal)
                }
                categoriesSection
            }
            .padding(.top, 8)
            .padding(.bottom, 24) // the bottom bar's space comes from the safe area
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .background(AppColor.screenBackground)
        .animation(AppAnimation.listChange, value: recentSearches.items.map(\.trackId))
    }

    // MARK: - Buscado recientemente

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                sectionTitle("Recently searched")
                Spacer()
                Button("Clear") {
                    withAnimation(AppAnimation.listChange) { recentSearches.clear() }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.lavenderInk)
                .accessibilityLabel("Clear recent searches")
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 14) {
                    ForEach(recentSearches.items, id: \.trackId) { podcast in
                        Button {
                            onOpenPodcast(podcast)
                        } label: {
                            RecentSearchItem(podcast: podcast)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Remove from recents", systemImage: "minus.circle", role: .destructive) {
                                withAnimation(AppAnimation.listChange) { recentSearches.remove(podcast) }
                            }
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Explorar categorías

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Explore categories")
                .padding(.horizontal, 20)

            if !genresViewModel.genre.isEmpty {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(genresViewModel.genre.enumerated()), id: \.offset) { index, genre in
                        Button {
                            onSelectGenre(genre)
                        } label: {
                            GenrePodcastCell(genre: genre, index: index)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            } else if genresViewModel.errorMessage != nil {
                errorState
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            }
        }
    }

    private var errorState: some View {
        VStack(spacing: 10) {
            Text("Couldn't load the categories.")
                .font(.system(size: 15))
                .foregroundStyle(.black.opacity(0.55))
            Button("Try again") {
                genresViewModel.loadGenre()
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppColor.lavenderInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }

    private func sectionTitle(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(AppColor.ink)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Recent item

/// Cover + name of a podcast searched recently.
private struct RecentSearchItem: View {
    let podcast: Podcast

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .frame(width: 72, height: 72)
                .overlay { PodcastImage(source: podcast.artworkUrl600) }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(podcast.trackName ?? "")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColor.ink.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(width: 72, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    SearchExploreView(
        genresViewModel: GenresViewModel(repository: GenresRepositoryImpl(remoteDataSource: PodcastRemoteDataService())),
        onOpenPodcast: { _ in },
        onSelectGenre: { _ in }
    )
    .environment(\.recentSearches, .preview)
}
