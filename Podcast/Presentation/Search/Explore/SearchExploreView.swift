//
//  SearchExploreView.swift
//  Podcast
//

import SwiftUI

/// What Search shows before you type: the podcasts you searched recently and
/// the categories, as a gallery of big cards you swipe through.
struct SearchExploreView: View {

    let genresViewModel: GenresViewModel
    let onOpenPodcast: (Podcast) -> Void
    let onSelectGenre: (Genre) -> Void

    @Environment(\.recentSearches) private var recentSearches
    /// Owned by the view: the covers stay while Search lives.
    @State private var genreCovers = GenreCoversViewModel()

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
                .font(AppFont.link)
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
                GenreGallery(
                    genres: genresViewModel.genre,
                    covers: genreCovers,
                    onSelect: onSelectGenre
                )
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
                .font(AppFont.body)
                .foregroundStyle(AppColor.Text.secondary)
            Button("Try again") {
                genresViewModel.loadGenre()
            }
            .font(AppFont.link)
            .foregroundStyle(AppColor.lavenderInk)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
    }

    private func sectionTitle(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(AppFont.sectionTitle)
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
                .font(AppFont.captionStrong)
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

// MARK: - Category gallery

/// The categories as big cards, one at a time with the next one peeking.
/// Swipe sideways; a counter below says where you are ("3 · 16").
private struct GenreGallery: View {

    let genres: [Genre]
    let covers: GenreCoversViewModel
    let onSelect: (Genre) -> Void

    /// The card in the middle. Owned here: only the counter reads it.
    @State private var currentID: String?

    private var position: Int {
        (genres.firstIndex { $0.id == currentID } ?? 0) + 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 14) {
                    ForEach(Array(genres.enumerated()), id: \.element.id) { index, genre in
                        Button {
                            onSelect(genre)
                        } label: {
                            GenreGalleryCard(
                                genre: genre,
                                color: GenreGalleryCard.color(for: index),
                                coverURLs: covers.coverURLs(for: genre)
                            )
                        }
                        .buttonStyle(.plain)
                        // The next card peeks in from the right.
                        .containerRelativeFrame(.horizontal) { length, _ in length - 70 }
                        .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.92)
                                .opacity(phase.isIdentity ? 1 : 0.55)
                        }
                        .task { await covers.load(genre) }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentID)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .scrollIndicators(.hidden)

            Text(verbatim: "\(position) · \(genres.count)")
                .font(AppFont.footnote)
                .monospacedDigit()
                .foregroundStyle(AppColor.Text.secondary)
                .padding(.horizontal, 20)
                .accessibilityHidden(true)
        }
    }
}

/// A big category card: its color, the covers of its top two podcasts in
/// the corner, and its name in serif at the bottom.
private struct GenreGalleryCard: View {

    let genre: Genre
    let color: Color
    let coverURLs: [String]

    var body: some View {
        color
            .frame(height: 380)
            .overlay(alignment: .topLeading) {
                HStack(spacing: -12) {
                    ForEach(0..<2, id: \.self) { position in
                        PodcastImage(
                            source: coverURLs.indices.contains(position) ? coverURLs[position] : nil,
                            placeholder: .white.opacity(position == 0 ? 0.6 : 0.4)
                        )
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 4)
                    }
                }
                .padding(20)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(genre.name)
                        .font(AppFont.editorialHero)
                        .foregroundStyle(AppColor.Text.onPastel)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text("Explore")
                        .font(AppFont.footnote.weight(.semibold))
                        .foregroundStyle(AppColor.Text.onPastel.opacity(0.7))
                }
                .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 14, y: 10)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(genre.name)
            .accessibilityAddTraits(.isButton)
    }

    /// Cycles the palette without repeating the previous card's color.
    static func color(for index: Int) -> Color {
        let palette = AppColor.palette
        var newIndex = index % palette.count
        if index > 0 && newIndex == (index - 1) % palette.count {
            newIndex = (newIndex + 1) % palette.count
        }
        return palette[newIndex]
    }
}
