//
//  GenreRankingView.swift
//  Podcast
//

import SwiftUI

/// A category, pushed from Search: "CATEGORY · 31 PODCASTS", its name big in
/// serif, the number 1 as a card, and the rest of the ranking under it.
struct GenreRankingView: View {

    let viewModel: GenreRankingViewModel
    let onOpenPodcast: (Podcast) -> Void
    let onPlay: (Episode) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 18)
                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .task { viewModel.load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.genre.name)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppColor.Text.primary)
                .accessibilityAddTraits(.isHeader)
            Text(overline)
                .font(.subheadline)
                .foregroundStyle(AppColor.Text.secondary)
        }
    }

    /// "Category · 31 podcasts" once loaded.
    private var overline: String {
        let count = viewModel.podcasts.count
        guard count > 0 else { return String(localized: "Category") }
        return String(localized: "Category · \(count) podcasts")
    }

    @ViewBuilder
    private var content: some View {
        if let first = viewModel.podcasts.first {
            TopPodcastCard(
                podcast: first,
                isPreparing: viewModel.preparingPodcastID == first.trackId,
                onOpen: { onOpenPodcast(first) },
                onListen: { listen(to: first) }
            )
            .padding(.bottom, 8)

            ForEach(Array(viewModel.podcasts.dropFirst().enumerated()), id: \.element.trackId) { offset, podcast in
                Button {
                    onOpenPodcast(podcast)
                } label: {
                    PodcastCellUI(podcast: podcast, rank: offset + 2, coverSide: 64)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .bottom) { Divider() }
            }
        } else if viewModel.error != nil {
            VStack(spacing: 10) {
                Text("Couldn't load this category.")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.secondary)
                Button("Try again") { viewModel.load() }
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.Accent.strong)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        }
    }

    private func listen(to podcast: Podcast) {
        Task {
            if let episode = await viewModel.newestEpisode(of: podcast) {
                onPlay(episode)
            }
        }
    }
}
