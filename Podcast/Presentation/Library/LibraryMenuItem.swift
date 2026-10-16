//
//  LibraryMenuItem.swift
//  Podcast
//
//  Created by Jonathan Mora on 09/06/26.
//

import SwiftUI

// MARK: - Models

struct LibraryMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let destination: LibraryDestination
}

// MARK: - LibraryView

struct LibraryView: View {
    
    let actions: LibraryActions
    @Environment(\.recentlyPlayed) private var recentlyPlayed
    @Environment(\.playerManager) private var playerManager

    private let menuItems: [LibraryMenuItem] = [
//        .init(title: "Programas",        systemImage: "square.stack", libraryDestination: .),
//        .init(title: "Canales",          systemImage: "play.tv"),
//        .init(title: "Categorías",       systemImage: "square.grid.2x2"),
        .init(title: "Guardados",        systemImage: "bookmark", destination: .guardados),
        .init(title: "Descargas",        systemImage: "arrow.down.circle", destination: .descargas),
        .init(title: "Episodios más recientes", systemImage: "clock", destination: .podcast(id: 0))
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
                .padding(.bottom, 120)
            }
            .background(Color.libraryBackground.ignoresSafeArea())

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
            Text("Actualizaciones recientes")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.black)

            if recentlyPlayed.items.isEmpty {
                Text("Lo que escuches aparecerá aquí.")
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
                            Button("Quitar de recientes", systemImage: "minus.circle", role: .destructive) {
                                withAnimation { recentlyPlayed.remove(item) }
                            }
                        }
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: recentlyPlayed.items.map(\.id))
            }
        }
    }
}

// MARK: - Menu Row

struct LibraryMenuRow: View {
    let item: LibraryMenuItem

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.systemImage)
                .font(.system(size: 20))
                .foregroundStyle(Color(.black))
                .frame(width: 28)

            Text(item.title)
                .font(.system(size: 17))
                .foregroundStyle(.black)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.gray.opacity(0.6))
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

// MARK: - Recent Update Card

struct RecentUpdateCard: View {
    let item: RecentlyPlayed
    @Environment(\.playerManager) private var playerManager

    private var isCurrent: Bool {
        playerManager.currentEpisode?.streamUrl == item.id
    }

    /// Live progress for the episode that's playing, saved progress for the rest.
    private var progress: Double {
        isCurrent ? Double(playerManager.viewModel.progress) : item.progress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Clear square + overlay: the cover always fills the same square
            // (before, `.aspectRatio(.fill)` after `.frame` could overflow).
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay { PodcastImage(source: item.episode.imageUrl) }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    if isCurrent {
                        Label("Sonando", systemImage: "waveform")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AppColor.lavender))
                            .padding(8)
                    }
                }

            Text(item.episode.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black) // was .white on a light background: unreadable
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 4) {
                Text(item.lastPlayedAt, format: .relative(presentation: .named))
                Text("·")
                Text(item.episode.author)
            }
            .font(.system(size: 12))
            .foregroundStyle(.black.opacity(0.5))
            .lineLimit(1)

            if progress > 0.01 {
                ProgressView(value: min(progress, 1))
                    .tint(AppColor.lavender)
                    .accessibilityLabel(progress >= 0.98 ? "Terminado" : "Escuchado \(Int(progress * 100)) por ciento")
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Colors

private extension Color {
    static let libraryBackground = Color(red: 0.96, green: 0.96, blue: 0.96)

}

// MARK: - Preview

#Preview {
    LibraryView(actions: LibraryActions())
        .environment(\.recentlyPlayed, .preview)
        .environment(\.playerManager, .preview)
}


enum LibraryDestination {
    case guardados
    case descargas
//    case programas
//    case canales
//    case categorias
    case podcast(id: Int)
}

@MainActor
final class LibraryActions {
    private let stream: AsyncStream<LibraryDestination>
    private let continuation: AsyncStream<LibraryDestination>.Continuation

    var events: AsyncStream<LibraryDestination> { stream }

    init() {
        var continuation: AsyncStream<LibraryDestination>.Continuation!
        stream = AsyncStream { continuation = $0 }
        self.continuation = continuation
    }

    func send(_ destination: LibraryDestination) {
        continuation.yield(destination)
    }
}
