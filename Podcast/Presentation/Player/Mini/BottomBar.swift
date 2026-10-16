//
//  BottomBar.swift
//  Podcast
//

import SwiftUI

/// The app's only bottom bar: what's playing on the left, search on the right.
/// With nothing playing it becomes a single "Buscar podcasts" pill.
struct BottomBar: View {

    @Environment(\.playerManager) private var manager
    let onSearch: () -> Void

    static let height: CGFloat = 64

    var body: some View {
        Group {
            if let episode = manager.currentEpisode {
                playingBar(episode)
            } else {
                searchOnlyBar
            }
        }
        .frame(height: Self.height)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }

    // MARK: - Something is playing

    private func playingBar(_ episode: Episode) -> some View {
        HStack(spacing: 4) {
            // Info area opens the full player.
            Button {
                manager.expand()
            } label: {
                HStack(spacing: 10) {
                    PodcastImage(source: episode.imageUrl)
                        .frame(width: 44, height: 44)
                        .overlay(alignment: .bottomLeading) {
                            // Progress lives on the artwork's bottom edge.
                            GeometryReader { geo in
                                Rectangle()
                                    .fill(AppColor.lavender)
                                    .frame(width: geo.size.width * CGFloat(manager.viewModel.progress), height: 3)
                                    .frame(maxHeight: .infinity, alignment: .bottom)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(episode.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                        Text(subtitle(for: episode))
                            .font(.system(size: 11))
                            .monospacedDigit()
                            .foregroundStyle(.black.opacity(0.55))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Abre el reproductor")

            Button {
                manager.togglePlayPause()
            } label: {
                Image(systemName: manager.viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(manager.viewModel.isPlaying ? "Pausar" : "Reproducir")

            Rectangle()
                .fill(.black.opacity(0.1))
                .frame(width: 1, height: 28)
                .accessibilityHidden(true)

            searchButton
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
    }

    private func subtitle(for episode: Episode) -> String {
        let remaining = manager.viewModel.remainingTimeText
        return remaining.isEmpty ? episode.author : "\(episode.author) · −\(remaining)"
    }

    // MARK: - Nothing playing

    private var searchOnlyBar: some View {
        Button(action: onSearch) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                Text("Buscar podcasts")
                    .font(.system(size: 15, weight: .medium))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 22)
            .frame(maxHeight: .infinity)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var searchButton: some View {
        Button(action: onSearch) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 48, height: 48)
        }
        .accessibilityLabel("Buscar")
    }
}
