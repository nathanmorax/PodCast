//
//  BrowsePodcastsSection.swift
//  Podcast
//

import SwiftUI

/// "Browse podcasts": category chips and a row of shows for the chosen one.
/// "Show all" opens the interests picker (the one from the first launch).
struct BrowsePodcastsSection: View {

    let viewModel: BrowseViewModel
    let interests: [Genre]
    let onOpenPodcast: (Podcast) -> Void
    let onShowAll: () -> Void

    /// The chosen chip. Owned here: only this section changes with it.
    @State private var selected: BrowseViewModel.Chip = .pickedForYou

    private var chips: [BrowseViewModel.Chip] {
        BrowseViewModel.chips(interests: interests)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LibrarySectionHeader(title: "Browse podcasts", onShowAll: onShowAll)

            ChipRow(chips: chips, selected: $selected)

            row
                .frame(minHeight: BrowseCover.height, alignment: .top)
                .animation(AppAnimation.listChange, value: viewModel.podcasts(for: selected).map(\.trackId))
        }
        // Interests changed and the chosen one is gone: back to the first.
        .onChange(of: interests.map(\.id)) {
            if !chips.contains(selected) { selected = .pickedForYou }
        }
        .task(id: selected) {
            await viewModel.load(selected, interests: interests)
        }
    }

    @ViewBuilder
    private var row: some View {
        let podcasts = viewModel.podcasts(for: selected)
        if !podcasts.isEmpty {
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(podcasts, id: \.trackId) { podcast in
                        Button {
                            onOpenPodcast(podcast)
                        } label: {
                            BrowseCover(podcast: podcast)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .scrollIndicators(.hidden)
        } else if viewModel.failed.contains(selected) {
            Button("Try again") {
                Task { await viewModel.load(selected, interests: interests) }
            }
            .font(AppFont.label)
            .foregroundStyle(AppColor.Accent.strong)
            .frame(maxWidth: .infinity)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Chips

/// "Picked for you" · Comedy · Science… The chosen one is filled.
private struct ChipRow: View {

    let chips: [BrowseViewModel.Chip]
    @Binding var selected: BrowseViewModel.Chip

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(chips) { chip in
                    let isOn = chip == selected
                    Button {
                        withAnimation(AppAnimation.selection) { selected = chip }
                    } label: {
                        Text(title(of: chip))
                            .font(AppFont.label)
                            .foregroundStyle(isOn ? AppColor.screenBackground : AppColor.Text.primary)
                            .padding(.horizontal, 16)
                            .frame(height: 38)
                            .background(isOn ? AppColor.Text.primary : AppColor.Surface.muted, in: .capsule)
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: selected)
    }

    private func title(of chip: BrowseViewModel.Chip) -> String {
        switch chip {
        case .pickedForYou: String(localized: "Picked for you")
        case .genre(let genre): genre.name
        }
    }
}

// MARK: - Cover

/// A show in the row: its cover, its category small, its name in serif.
private struct BrowseCover: View {

    let podcast: Podcast

    static let side: CGFloat = 112
    static let height: CGFloat = side + 8 + 54

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Color.clear
                .frame(width: Self.side, height: Self.side)
                .overlay { PodcastImage(source: podcast.artworkUrl600) }
                .clipShape(RoundedRectangle(cornerRadius: LibraryCover.cornerRadius, style: .continuous))
                .padding(.bottom, 4)
                .accessibilityHidden(true)

            if let genre = podcast.primaryGenreName, !genre.isEmpty {
                Text(genre)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
            }
            Text(podcast.trackName ?? "")
                .font(AppFont.cardTitle)
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(2)
        }
        .frame(width: Self.side, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
