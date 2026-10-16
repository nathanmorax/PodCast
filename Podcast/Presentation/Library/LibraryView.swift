//
//  LibraryView.swift
//  Podcast
//

import SwiftUI

struct LibraryView: View {
    
    let actions: LibraryActions
    @Environment(\.recentlyPlayed) private var recentlyPlayed
    @Environment(\.playerManager) private var playerManager

    private let menuItems: [LibraryMenuItem] = [
//        .init(title: "Programas",        systemImage: "square.stack", libraryDestination: .),
//        .init(title: "Canales",          systemImage: "play.tv"),
//        .init(title: "Categorías",       systemImage: "square.grid.2x2"),
        .init(title: String(localized: "Saved"),        systemImage: "bookmark", destination: .guardados),
        .init(title: String(localized: "Downloads"),        systemImage: "arrow.down.circle", destination: .descargas),
        .init(title: String(localized: "Latest episodes"), systemImage: "clock", destination: .podcast(id: 0))
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    menuSection
                        .padding(.top, 8)

                    recentUpdatesSection
                        .padding(.top, 28)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24) // the bottom bar's space comes from the safe area
            }
            .background(AppColor.screenBackground.ignoresSafeArea())

            .toolbarBackground(AppColor.background, for: .navigationBar)
        }
        // NOT .preferredColorScheme(.dark): that one is a preference for the whole
        // window, so visiting this tab flipped the entire app to dark mode.
        // .environment(\.colorScheme) only affects this view's subtree.
        .environment(\.colorScheme, .dark)
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
                    Divider().background(Color.white.opacity(0.08))
                }
            }
        }
    }

    // MARK: - Actualizaciones recientes

    /// The episodes the listener played, most recent first (RecentlyPlayedManager).
    private var recentUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recently played")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.black)

            if recentlyPlayed.items.isEmpty {
                Text("What you listen to will show up here.")
                    .font(.system(size: 15))
                    .foregroundStyle(.black.opacity(0.5))
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
}
