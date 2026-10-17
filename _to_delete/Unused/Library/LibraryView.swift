//
//  LibraryView.swift
//  Podcast
//

import SwiftUI

struct LibraryView: View {
    
    let actions: LibraryActions
    @Environment(\.recentlyPlayed) private var recentlyPlayed
    @Environment(\.playerManager) private var playerManager
    @Environment(\.favoritesManager) private var favoritesManager

    private let menuItems: [LibraryMenuItem] = [
//        .init(title: "Programas",        systemImage: "square.stack", libraryDestination: .),
//        .init(title: "Canales",          systemImage: "play.tv"),
//        .init(title: "Categorías",       systemImage: "square.grid.2x2"),
        .init(title: String(localized: "Favorite episodes"), systemImage: "heart", destination: .guardados),
        .init(title: String(localized: "Downloads"),        systemImage: "arrow.down.circle", destination: .descargas),
        .init(title: String(localized: "Latest episodes"), systemImage: "clock", destination: .podcast(id: 0))
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        // No NavigationStack here: this view already lives in a UIKit
        // navigation stack (with the large title "Biblioteca"). A second one
        // added an empty bar on top and pushed the content down.
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                followingSection
                    .padding(.top, 8)

                menuSection
                    .padding(.top, 24)

                recentUpdatesSection
                    .padding(.top, 28)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24) // the bottom bar's space comes from the safe area
        }
        .background(AppColor.screenBackground.ignoresSafeArea())
    }

    // MARK: - Following

    /// The podcasts the listener follows (+ on a podcast's page). The first
    /// thing in Library: it's what they come back to.
    private var followingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Following")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.Text.primary)
                .accessibilityAddTraits(.isHeader)

            if favoritesManager.favorites.isEmpty {
                Text("Tap + on a podcast to follow it. It'll show up here.")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.secondary)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 14) {
                        ForEach(favoritesManager.favorites, id: \.trackId) { podcast in
                            Button {
                                actions.send(.openPodcast(podcast))
                            } label: {
                                PodcastTile(podcast: podcast)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Unfollow", systemImage: "minus.circle", role: .destructive) {
                                    withAnimation(AppAnimation.listChange) {
                                        favoritesManager.deleteFavorite(podcast)
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .contentMargins(.horizontal, 20, for: .scrollContent)
                .padding(.horizontal, -20) // edge to edge, aligned with the title
            }
        }
        .animation(AppAnimation.listChange, value: favoritesManager.favorites.map(\.trackId))
    }

    // MARK: - Menú

    private var menuSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(menuItems.enumerated()), id: \.element.id) { index, item in
                Button {
                    actions.send(item.destination)
                } label: {
                    LibraryMenuRow(item: item)
                }
                .buttonStyle(.plain)
                if index < menuItems.count - 1 {
                    Divider()
                }
            }
        }
    }

    // MARK: - Actualizaciones recientes

    /// The episodes the listener played, most recent first (RecentlyPlayedManager).
    private var recentUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recently played")
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.Text.primary)

            if recentlyPlayed.items.isEmpty {
                Text("What you listen to will show up here.")
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.Text.secondary)
            } else {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(recentlyPlayed.items) { item in
                        Button {
                            playerManager.play(item.episode)
                        } label: {
                            RecentUpdateCard(item: item)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Remove from recents", systemImage: "minus.circle", role: .destructive) {
                                withAnimation(AppAnimation.listChange) { recentlyPlayed.remove(item) }
                            }
                        }
                    }
                }
                .animation(AppAnimation.listChange, value: recentlyPlayed.items.map(\.id))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LibraryView(actions: LibraryActions())
        .environment(\.recentlyPlayed, .preview)
        .environment(\.playerManager, .preview)
        .environment(\.favoritesManager, .preview)
}
