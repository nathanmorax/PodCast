//
//  HomeEpisodeRow.swift
//  Podcast
//

import SwiftUI

/// An episode in "Latest Episodes": the small cover next to the title, two
/// lines of what it's about, the date and the show; then ▶, how far along
/// (a short bar and the time left) or its length, save (+) and ⋮. The
/// upper part opens the episode, zooming out of the cover.
struct HomeEpisodeRow: View {

    let item: PodcastEpisode
    /// Its listening, when it was started.
    let played: RecentlyPlayed?
    let onOpen: () -> Void

    var body: some View {
        let actions = EpisodeActionViewModel(episode: item.episode)

        VStack(alignment: .leading, spacing: 12) {
            Button(action: onOpen) {
                info
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the episode")

            controls(actions)
        }
        .padding(.vertical, 16)
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                ZoomSourceImage(
                    id: .episode(item.episode.streamUrl, section: .feed),
                    source: item.feedArtwork,
                    cornerRadius: 8
                )
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

                Text(item.episode.title)
                    .font(.headline.weight(.medium))
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !item.episode.description.isEmpty {
                Text(item.episode.description)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            HStack(spacing: 16) {
                Text(item.episode.pubDate, format: .dateTime.day().month(.twoDigits).year())
                Text(item.showName)
                    .lineLimit(1)
            }
            .font(.footnote)
            .foregroundStyle(AppColor.Text.secondary)
        }
        .contentShape(Rectangle())
    }

    private func controls(_ actions: EpisodeActionViewModel) -> some View {
        HStack(spacing: 12) {
            Button {
                play(actions)
            } label: {
                Image(systemName: actions.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(AppColor.Text.primary)
                    .offset(x: actions.isPlaying ? 0 : 1)
                    .frame(width: 36, height: 36)
                    .background(AppColor.Surface.muted, in: Circle())
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(actions.isPlaying ? Text("Pause") : Text("Play"))

            if let played, played.progress > 0, played.progress < RecentlyPlayed.finishedThreshold {
                Capsule()
                    .fill(AppColor.Text.primary.opacity(0.15))
                    .frame(width: 64, height: 4)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(AppColor.Text.primary)
                            .frame(width: 64 * played.progress, height: 4)
                    }
                    .accessibilityHidden(true)
                Text("\(played.minutesLeftText) left")
                    .font(.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
            } else {
                Text(item.episode.durationDisplayText)
                    .font(.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                actions.toggleBookmark()
            } label: {
                Image(systemName: actions.isBookmarked ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 22, weight: .light))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(actions.isBookmarked ? AppColor.Accent.strong : AppColor.Text.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: actions.isBookmarked) { _, saved in saved }
            .accessibilityLabel(actions.isBookmarked ? Text("Saved") : Text("Save"))

            Menu {
                EpisodeActionsMenuItems(actions: actions)
            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColor.Text.secondary)
                    .frame(width: 32, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More")
        }
    }

    /// A started one goes on from where it was left; the rest play or pause.
    private func play(_ actions: EpisodeActionViewModel) {
        let manager = PlayerManager.shared
        let isCurrent = manager.currentEpisode?.streamUrl == item.episode.streamUrl
        if let played, !isCurrent {
            manager.play(item.episode, presentation: .mini, from: played.resumeProgress)
        } else {
            actions.playOrPause()
        }
    }
}

extension PodcastEpisode {

    /// The episode's own artwork, or its show's.
    var feedArtwork: String? {
        if let image = episode.imageUrl, !image.isEmpty { return image }
        return podcast.artworkUrl600
    }

    var showName: String { podcast.trackName ?? episode.author }
}
