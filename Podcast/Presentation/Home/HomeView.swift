//
//  HomeView.swift
//  Podcast
//

import SwiftUI
import Combine

/// "Inicio": pick up where you left off, your podcasts, and what you played.
struct HomeView: View {

    @Environment(\.recentlyPlayed) private var recentlyPlayed
    @Environment(\.playerManager) private var playerManager

    var favoritesPublisher: AnyPublisher<[Podcast], Never> = FavoritesPodcastManager.shared.favoritesPublisher
    let onOpenPodcast: (Podcast) -> Void
    let onSearch: () -> Void

    @State private var favorites: [Podcast] = []

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
                    section("Continuar escuchando") {
                        ContinueListeningCard(item: item)
                            .padding(.horizontal, 20)
                    }
                }

                if !favorites.isEmpty {
                    section("Tus podcasts") { favoritesRow }
                }

                if !otherRecents.isEmpty {
                    section("Escuchado recientemente") { recentsRow }
                }

                if isEmpty {
                    emptyState
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24) // the bottom bar's space comes from the safe area
        }
        .scrollIndicators(.hidden)
        .background(Color.homeBackground.ignoresSafeArea())
        .onReceive(favoritesPublisher) { favorites = $0 }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: recentlyPlayed.items.map(\.id))
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.black.opacity(0.45))
                .textCase(.uppercase)
            Text("Inicio")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.black)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, 20)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
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
                        Button("Quitar de recientes", systemImage: "minus.circle", role: .destructive) {
                            withAnimation { recentlyPlayed.remove(item) }
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
                .foregroundStyle(Color.homeAccentInk)
                .accessibilityHidden(true)
            Text("Tu inicio está vacío")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
            Text("Busca un podcast y empieza a escuchar. Aquí podrás retomarlo donde lo dejaste.")
                .font(.system(size: 15))
                .foregroundStyle(.black.opacity(0.55))
                .multilineTextAlignment(.center)
            Button(action: onSearch) {
                Label("Buscar podcasts", systemImage: "magnifyingglass")
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

// MARK: - Continue listening

/// Big card for the last unfinished episode: play/pause right there.
struct ContinueListeningCard: View {

    let item: RecentlyPlayed
    @Environment(\.playerManager) private var playerManager

    private var isCurrent: Bool {
        playerManager.currentEpisode?.streamUrl == item.id
    }

    private var isPlaying: Bool {
        isCurrent && playerManager.viewModel.isPlaying
    }

    /// Live progress for the episode that's loaded, saved progress otherwise.
    private var progress: Double {
        isCurrent ? Double(playerManager.viewModel.progress) : item.progress
    }

    var body: some View {
        HStack(spacing: 14) {
            Button {
                playerManager.play(item.episode)
            } label: {
                HStack(spacing: 14) {
                    Color.clear
                        .frame(width: 88, height: 88)
                        .overlay { PodcastImage(source: item.episode.imageUrl) }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.episode.author)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.black.opacity(0.5))
                            .lineLimit(1)
                        Text(item.episode.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        ProgressView(value: min(max(progress, 0), 1))
                            .tint(Color.homeAccentInk)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Abre el reproductor")

            Button {
                if isCurrent {
                    playerManager.togglePlayPause()
                } else {
                    playerManager.play(item.episode, presentation: .mini)
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(.black)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(AppColor.lavender))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? "Pausar" : "Continuar")
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
    }
}

// MARK: - Podcast tile

private struct PodcastTile: View {
    let podcast: Podcast

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .frame(width: 132, height: 132)
                .overlay { PodcastImage(source: podcast.artworkUrl600) }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(podcast.trackName ?? "")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text(podcast.artistName ?? "")
                .font(.system(size: 12))
                .foregroundStyle(.black.opacity(0.5))
                .lineLimit(1)
        }
        .frame(width: 132, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Colors

private extension Color {
    static let homeBackground = Color(red: 0.96, green: 0.96, blue: 0.96)
    /// #4C40A0
    static let homeAccentInk = Color(red: 0.298, green: 0.251, blue: 0.627)
}

// MARK: - Preview

#Preview {
    HomeView(
        favoritesPublisher: Just([]).eraseToAnyPublisher(),
        onOpenPodcast: { _ in },
        onSearch: {}
    )
    .environment(\.recentlyPlayed, .preview)
    .environment(\.playerManager, .preview)
}
