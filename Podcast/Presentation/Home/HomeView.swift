//
//  HomeView.swift
//  Podcast
//

import SwiftUI

/// "Inicio": pick up where you left off, your podcasts, and what you played.
struct HomeView: View {

    @Environment(\.recentlyPlayed) private var recentlyPlayed
    @Environment(\.playerManager) private var playerManager
    @Environment(\.favoritesManager) private var favoritesManager

    let onOpenPodcast: (Podcast) -> Void
    let onSearch: () -> Void

    private var favorites: [Podcast] { favoritesManager.favorites }

    /// The most recent episode that isn't finished.
    private var continueItem: RecentlyPlayed? {
        recentlyPlayed.items.first { $0.progress < 0.98 }
    }

    private var otherRecents: [RecentlyPlayed] {
        Array(recentlyPlayed.items.filter { $0.id != continueItem?.id }.prefix(10))
    }

    private var isEmpty: Bool {
        recentlyPlayed.items.isEmpty && favorites.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                header

                if let item = continueItem {
                    section("Continue listening") {
                        ContinueListeningCard(item: item)
                            .padding(.horizontal, 20)
                    }
                }

                if !favorites.isEmpty {
                    section("Your podcasts") { favoritesRow }
                }

                if !otherRecents.isEmpty {
                    section("Recently played") { recentsRow }
                }

                if isEmpty {
                    emptyState
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24) // the bottom bar's space comes from the safe area
        }
        .scrollIndicators(.hidden)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .animation(AppAnimation.listChange, value: recentlyPlayed.items.map(\.id))
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.black.opacity(0.45))
                .textCase(.uppercase)
            Text("Home")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.black)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, 20)
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 20)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    // MARK: - Rows

    private var favoritesRow: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 14) {
                ForEach(favorites, id: \.trackId) { podcast in
                    Button {
                        onOpenPodcast(podcast)
                    } label: {
                        PodcastTile(podcast: podcast)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }

    private var recentsRow: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 14) {
                ForEach(otherRecents) { item in
                    Button {
                        playerManager.play(item.episode)
                    } label: {
                        RecentUpdateCard(item: item)
                            .frame(width: 150)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Remove from recents", systemImage: "minus.circle", role: .destructive) {
                            withAnimation(AppAnimation.listChange) { recentlyPlayed.remove(item) }
                        }
                    }
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "waveform")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(AppColor.lavenderInk)
                .accessibilityHidden(true)
            Text("Your home is empty")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
            Text("Search for a podcast and start listening. You'll pick it up here right where you left off.")
                .font(.system(size: 15))
                .foregroundStyle(.black.opacity(0.55))
                .multilineTextAlignment(.center)
            Button(action: onSearch) {
                Label("Search podcasts", systemImage: "magnifyingglass")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(AppColor.lavender))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 48)
    }
}

// MARK: - Preview

#Preview {
    HomeView(
        onOpenPodcast: { _ in },
        onSearch: {}
    )
    .environment(\.recentlyPlayed, .preview)
    .environment(\.playerManager, .preview)
    .environment(\.favoritesManager, .preview)
}
