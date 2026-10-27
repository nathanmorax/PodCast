//
//  SearchResultsView.swift
//  Podcast
//

import SwiftUI

/// What Search shows while you type: Podcasts (with + to follow right
/// there) and Episodes from any show, each with its first sentence.
struct SearchResultsView: View {

    let viewModel: PodcastSearchViewModel
    let onOpenPodcast: (Podcast) -> Void
    let onOpenEpisode: (EpisodeSearchResult) -> Void

    /// Podcasts shown before "See all".
    static let podcastPreviewCount = 3

    @State private var showsAllPodcasts = false

    private var podcasts: [Podcast] {
        showsAllPodcasts ? viewModel.podcasts : Array(viewModel.podcasts.prefix(Self.podcastPreviewCount))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !viewModel.podcasts.isEmpty {
                    podcastsSection
                }
                if !viewModel.episodes.isEmpty {
                    episodesSection
                        .padding(.top, viewModel.podcasts.isEmpty ? 0 : 24)
                }
                if viewModel.podcasts.isEmpty, viewModel.episodes.isEmpty, viewModel.error != nil {
                    Text("Couldn't search. Check your connection and try again.")
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.Text.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        // New text, new results: back to the short list.
        .onChange(of: viewModel.podcasts.map(\.trackId)) { showsAllPodcasts = false }
    }

    // MARK: - Podcasts

    private var podcastsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SearchSectionHeader(title: "Podcasts")
                .padding(.bottom, 2)

            ForEach(podcasts, id: \.trackId) { podcast in
                // Two targets side by side: the row opens, + follows.
                HStack(spacing: 12) {
                    Button {
                        onOpenPodcast(podcast)
                    } label: {
                        PodcastCellUI(podcast: podcast, coverSide: 64)
                    }
                    .buttonStyle(.plain)

                    FollowButton(podcast: podcast)
                }
                .overlay(alignment: .bottom) { Divider() }
            }

            let hidden = viewModel.podcasts.count - Self.podcastPreviewCount
            if !showsAllPodcasts, hidden > 0 {
                Button("See all \(viewModel.podcasts.count)") {
                    withAnimation(AppAnimation.listChange) { showsAllPodcasts = true }
                }
                .font(AppFont.captionStrong)
                .foregroundStyle(AppColor.Accent.strong)
                .padding(.top, 12)
            }
        }
    }

    // MARK: - Episodes

    private var episodesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SearchSectionHeader(title: "Episodes")

            ForEach(viewModel.episodes) { result in
                EpisodeResultRow(result: result) { onOpenEpisode(result) }
                    .overlay(alignment: .bottom) { Divider() }
            }
        }
    }
}
