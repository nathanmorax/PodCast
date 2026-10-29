//
//  ContinueListeningSection.swift
//  Podcast
//

import SwiftUI

/// "Continue listening": the episodes you started and didn't finish, the
/// last one played first, as compact rows (finished ones live in the
/// Library's History). Each row: the cover, the show, the title in serif,
/// "23 min left", and ▶ inside a ring that fills with how far you got.
///
/// ▶ resumes it in the mini player; tapping the row opens its details;
/// holding it offers Resume, Details and Remove.
struct ContinueListeningSection: View {

    let items: [RecentlyPlayed]
    let onResume: (RecentlyPlayed) -> Void
    let onOpen: (RecentlyPlayed) -> Void
    let onRemove: (RecentlyPlayed) -> Void
    let onShowAll: () -> Void

    /// Rows shown; the rest are in the Library's History.
    static let limit = 3

    /// Unfinished ones, last played first. The one in the player counts
    /// even before its progress is saved.
    static func unfinished(_ items: [RecentlyPlayed]) -> [RecentlyPlayed] {
        items
            .filter { $0.progress < RecentlyPlayed.finishedThreshold }
            .sorted { $0.lastPlayedAt > $1.lastPlayedAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LibrarySectionHeader(
                title: "Continue listening",
                onShowAll: items.count > Self.limit ? onShowAll : nil
            )

            VStack(spacing: 0) {
                ForEach(items.prefix(Self.limit)) { item in
                    ZoomSourceHost(
                        id: .episode(item.episode.streamUrl, section: .recentlyPlayed),
                        cornerRadius: 0
                    ) {
                        ContinueRow(
                            item: item,
                            onResume: { onResume(item) },
                            onOpen: { onOpen(item) },
                            onRemove: { onRemove(item) }
                        )
                    }
                }
            }
        }
    }
}

private struct ContinueRow: View {

    let item: RecentlyPlayed
    let onResume: () -> Void
    let onOpen: () -> Void
    let onRemove: () -> Void

    // A ZoomSourceHost doesn't pass custom environment values on: the
    // shared player is read directly.
    private var playerManager: PlayerManager { .shared }

    private var isCurrent: Bool {
        playerManager.currentEpisode?.streamUrl == item.episode.streamUrl
    }

    private var isPlaying: Bool {
        isCurrent && playerManager.viewModel.isPlaying
    }

    /// Live for the episode in the player; as saved for the others.
    private var progress: Double {
        isCurrent ? Double(playerManager.viewModel.progress) : item.progress
    }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onOpen) {
                HStack(spacing: 14) {
                    RowArtwork(side: 56) {
                        PodcastImage(source: item.artworkSource, contentMode: .fill)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.episode.author)
                            .overlineStyle()
                            .lineLimit(1)
                        Text(item.episode.title)
                            .font(.system(.body, design: .serif, weight: .semibold))
                            .foregroundStyle(AppColor.Text.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text("\(item.minutesLeftText(at: progress)) left")
                            .font(.footnote)
                            .monospacedDigit()
                            .foregroundStyle(isCurrent ? AppColor.Accent.strong : AppColor.Text.secondary)
                            .contentTransition(.numericText())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Shows the episode's details")

            ProgressPlayButton(progress: progress, isPlaying: isPlaying, action: onResume)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .contextMenu {
            Button("Resume", systemImage: "play.fill", action: onResume)
            Button("Details", systemImage: "info.circle", action: onOpen)
            Button("Remove", systemImage: "minus.circle", role: .destructive, action: onRemove)
        }
    }
}

/// ▶ (or ❚❚) inside a thin ring that fills, in the accent, with how far
/// the episode got.
private struct ProgressPlayButton: View {

    let progress: Double
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(AppColor.Text.primary.opacity(0.12), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: max(0.02, min(progress, 1)))
                    .stroke(AppColor.Accent.soft, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: progress)
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColor.Text.primary)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 16, height: 16)
                    .offset(x: isPlaying ? 0 : 1)
            }
            .frame(width: 38, height: 38)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? Text("Pause") : Text("Resume"))
        .accessibilityValue(Text("\(Int(progress * 100)) percent played"))
    }
}
