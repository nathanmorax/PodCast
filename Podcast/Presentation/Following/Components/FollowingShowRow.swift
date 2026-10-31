//
//  FollowingShowRow.swift
//  Podcast
//

import SwiftUI

/// One show you follow: its rounded cover (a green dot when there's
/// something new), its name and who makes it, its newest episode ("Latest
/// · Tue · title"), "3 new" when there are, and ▶ for that newest episode.
/// The row opens the show (zooming out of the cover); ▶ plays right there.
struct FollowingShowRow: View {

    let show: FollowingShow
    let onOpen: () -> Void

    static let coverSide: CGFloat = 72

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                HStack(spacing: 14) {
                    Color.clear
                        .frame(width: Self.coverSide, height: Self.coverSide)
                        .overlay { ZoomSourceImage(podcast: show.podcast, cornerRadius: 14) }
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(alignment: .topTrailing) {
                            if show.newCount > 0 { newDot }
                        }
                        .accessibilityHidden(true)

                    details
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the show")

            if let latest = show.latest {
                PlayLatestButton(episode: latest)
            }
        }
        .padding(.vertical, 12)
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Text(show.podcast.trackName ?? "")
                    .font(.headline)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if show.newCount > 0 {
                    Text("\(show.newCount) new")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColor.Text.inverse)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(AppColor.Accent.strong, in: Capsule())
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            if let artist = show.podcast.artistName, !artist.isEmpty {
                Text(artist)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
            }
            if let latest = show.latest {
                Text("Latest · \(latest.pubDate.shortDayText()) · \(latest.title)")
                    .font(.footnote)
                    .foregroundStyle(AppColor.Text.tertiary)
                    .lineLimit(1)
            }
        }
    }

    /// The green dot on the cover's corner: new episodes.
    private var newDot: some View {
        Circle()
            .fill(AppColor.Accent.strong)
            .frame(width: 14, height: 14)
            .overlay { Circle().strokeBorder(AppColor.screenBackground, lineWidth: 2.5) }
            .offset(x: 4, y: -4)
    }
}

/// ▶ / ❚❚ for a show's newest episode, in a soft circle.
private struct PlayLatestButton: View {

    let episode: Episode

    var body: some View {
        let actions = EpisodeActionViewModel(episode: episode)
        Button {
            actions.playOrPause()
        } label: {
            Image(systemName: actions.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 13, weight: .bold))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(actions.isPlaying ? AppColor.Accent.strong : AppColor.Text.primary)
                .offset(x: actions.isPlaying ? 0 : 1)
                .frame(width: 40, height: 40)
                .background(AppColor.Surface.muted, in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(actions.isPlaying ? Text("Pause") : Text("Play latest episode"))
    }
}
