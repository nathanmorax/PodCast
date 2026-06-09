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

struct RecentPodcastUpdate: Identifiable {
    let id: Int
    let title: String
    let artworkURL: String?
    let timeAgo: String
    let newEpisodes: Int
}

// MARK: - LibraryView

struct LibraryView: View {
    
    let actions: LibraryActions

    private let menuItems: [LibraryMenuItem] = [
//        .init(title: "Programas",        systemImage: "square.stack", libraryDestination: .),
//        .init(title: "Canales",          systemImage: "play.tv"),
//        .init(title: "Categorías",       systemImage: "square.grid.2x2"),
        .init(title: "Guardados",        systemImage: "bookmark", destination: .guardados),
        .init(title: "Descargas",        systemImage: "arrow.down.circle", destination: .descargas),
        .init(title: "Episodios más recientes", systemImage: "clock", destination: .podcast(id: 0))
    ]

    private let recentUpdates: [RecentPodcastUpdate] = [
        .init(id: 1, title: "The Daily", artworkURL: nil, timeAgo: "Hace 10 h", newEpisodes: 1),
        .init(id: 2, title: "The Journal.", artworkURL: nil, timeAgo: "Ayer", newEpisodes: 1),
        .init(id: 3, title: "Up First from NPR", artworkURL: nil, timeAgo: "Ayer", newEpisodes: 1),
        .init(id: 4, title: "The Indicator from Planet Money", artworkURL: nil, timeAgo: "Ayer", newEpisodes: 1),
        .init(id: 5, title: "The Economics of Everyday Things", artworkURL: nil, timeAgo: "Ayer", newEpisodes: 1),
        .init(id: 6, title: "The Daily Stoic", artworkURL: nil, timeAgo: "Ayer", newEpisodes: 1)
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
        .preferredColorScheme(.dark)
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

    private var recentUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actualizaciones recientes")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.black)

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(recentUpdates) { podcast in
                    Button {
                        // navegar al podcast
                    } label: {
                        RecentUpdateCard(podcast: podcast)
                    }
                    .buttonStyle(.plain)
                }
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
    let podcast: RecentPodcastUpdate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PodcastImage(source: podcast.artworkURL)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(podcast.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text("\(podcast.timeAgo) · \(podcast.newEpisodes) nuevo")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
                .lineLimit(1)
        }
    }
}

// MARK: - Colors

private extension Color {
    static let libraryBackground = Color(red: 0.96, green: 0.96, blue: 0.96)

}

// MARK: - Preview

//#Preview {
//    LibraryView()
//}


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
