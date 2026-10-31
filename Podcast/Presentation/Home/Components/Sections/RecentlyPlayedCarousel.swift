//
//  RecentlyPlayedCarousel.swift
//  Podcast
//

import SwiftUI

/// "Recently played": one wide card at a time, swiped sideways, with dots
/// under them (the one in view in ink). Each card: the cover, the show,
/// the title, how far along (a bar and the time left) and ▶ to go on.
/// Tapping a card opens the episode (zooming out of its cover); holding it
/// offers Resume and Remove.
struct RecentlyPlayedCarousel: View {

    let items: [RecentlyPlayed]
    let onOpen: (RecentlyPlayed) -> Void
    let onRemove: (RecentlyPlayed) -> Void

    /// The card in view (nil until the first swipe: the first one).
    @State private var current: String?

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(items) { item in
                        RecentlyPlayedCard(
                            item: item,
                            onOpen: { onOpen(item) },
                            onRemove: { onRemove(item) }
                        )
                        // A bit narrower than the screen: the next card
                        // peeks out at the edge, fading.
                        .containerRelativeFrame(.horizontal) { width, _ in
                            items.count > 1 ? width * 0.86 : width
                        }
                        .id(item.id)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $current)
            .scrollIndicators(.hidden)
            .trailingFade(width: 40)

            if items.count > 1 {
                dots
            }
        }
    }

    /// One dot per card; the one in view is a short ink capsule.
    private var dots: some View {
        let selected = current ?? items.first?.id
        return HStack(spacing: 6) {
            ForEach(items) { item in
                let isOn = item.id == selected
                Capsule()
                    .fill(AppColor.Text.primary.opacity(isOn ? 1 : 0.2))
                    .frame(width: isOn ? 18 : 6, height: 6)
            }
        }
        .animation(AppAnimation.selection, value: selected)
        .accessibilityHidden(true)
    }
}

/// A card in Recently played, on a soft rounded block.
private struct RecentlyPlayedCard: View {

    let item: RecentlyPlayed
    let onOpen: () -> Void
    let onRemove: () -> Void

    @Environment(\.playerManager) private var playerManager

    private var isCurrent: Bool {
        playerManager.currentEpisode?.streamUrl == item.episode.streamUrl
    }

    private var isPlaying: Bool { isCurrent && playerManager.viewModel.isPlaying }

    /// Live for the episode in the player; as saved for the others.
    private var progress: Double {
        isCurrent ? Double(playerManager.viewModel.progress) : item.progress
    }

    private var isFinished: Bool { progress >= RecentlyPlayed.finishedThreshold }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onOpen) {
                HStack(spacing: 14) {
                    ZoomSourceImage(
                        id: .episode(item.episode.streamUrl, section: .recentlyPlayed),
                        source: item.episode.imageUrl,
                        cornerRadius: 12
                    )
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.episode.author)
                            .font(.footnote)
                            .foregroundStyle(AppColor.Text.secondary)
                            .lineLimit(1)
                        Text(item.episode.title)
                            .font(.headline)
                            .foregroundStyle(AppColor.Text.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        progressLine
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the episode")

            Button(action: resume) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(AppColor.Text.inverse)
                    .offset(x: isPlaying ? 0 : 1)
                    .frame(width: 44, height: 44)
                    .background(AppColor.Accent.strong, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? Text("Pause") : Text("Resume"))
        }
        .padding(12)
        .background(AppColor.Surface.muted, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contextMenu {
            Button("Resume", systemImage: "play.fill", action: resume)
            Button("Remove", systemImage: "minus.circle", role: .destructive, action: onRemove)
        }
    }

    /// A short bar and "23 min left" (or "Played" once finished).
    private var progressLine: some View {
        HStack(spacing: 8) {
            Capsule()
                .fill(AppColor.Text.primary.opacity(0.15))
                .frame(width: 56, height: 4)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(AppColor.Accent.strong)
                        .frame(width: 56 * min(max(progress, 0), 1), height: 4)
                }
                .accessibilityHidden(true)
            Group {
                if isFinished {
                    Text("Played")
                } else {
                    Text("\(item.minutesLeftText(at: progress)) left")
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .font(.footnote)
            .foregroundStyle(isCurrent ? AppColor.Accent.strong : AppColor.Text.secondary)
            .lineLimit(1)
        }
    }

    /// The one in the player pauses or goes on; another starts where it was
    /// left (from the top once finished), in the mini player.
    private func resume() {
        if isCurrent {
            playerManager.togglePlayPause()
        } else {
            playerManager.play(item.episode, presentation: .mini, from: item.resumeProgress)
        }
    }
}
