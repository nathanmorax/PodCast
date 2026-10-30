//
//  HomePostCard.swift
//  Podcast
//

import SwiftUI

/// One post in Home's feed: the show's cover in a circle, its name and its
/// category in an outlined chip, ••• (save, download, share); then the
/// episode in a big rounded image with a bookmark on its corner (and how
/// far along, for half-listened ones); its title, when it came out · how
/// long, and ▶. The image and title open the episode; the show's line
/// opens the show.
struct HomePostCard: View {

    let post: HomePost
    let onOpen: () -> Void
    let onOpenShow: (() -> Void)?

    static let imageRadius: CGFloat = 22

    var body: some View {
        let actions = EpisodeActionViewModel(episode: post.episode)

        VStack(alignment: .leading, spacing: 12) {
            header(actions)
                .padding(.horizontal, 20)

            Button(action: onOpen) {
                image(actions)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .accessibilityLabel(Text(post.episode.title))
            .accessibilityHint("Opens the episode")

            footer(actions)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Header

    private func header(_ actions: EpisodeActionViewModel) -> some View {
        HStack(spacing: 12) {
            Button {
                onOpenShow?()
            } label: {
                HStack(spacing: 12) {
                    PodcastImage(source: post.showArtwork)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.showName)
                            .font(.headline)
                            .foregroundStyle(AppColor.Text.primary)
                            .lineLimit(1)
                        if let genre = post.genre {
                            Text(genre)
                                .font(.caption)
                                .foregroundStyle(AppColor.Text.secondary)
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(AppColor.Text.tertiary, lineWidth: 1)
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(onOpenShow == nil)
            .accessibilityElement(children: .combine)
            .accessibilityHint(onOpenShow == nil ? Text(verbatim: "") : Text("Opens the show"))

            Menu {
                EpisodeActionsMenuItems(actions: actions)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More")
        }
    }

    // MARK: - Image

    private func image(_ actions: EpisodeActionViewModel) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZoomSourceImage(
                    id: .episode(post.episode.streamUrl, section: post.section),
                    source: post.artwork,
                    cornerRadius: Self.imageRadius
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: Self.imageRadius, style: .continuous))
            .overlay(alignment: .topTrailing) {
                bookmark(actions)
                    .padding(12)
            }
            .overlay(alignment: .bottom) {
                if let progress = post.progress {
                    progressLine(progress)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Self.imageRadius, style: .continuous))
    }

    /// Save, in a white circle on the image's corner.
    private func bookmark(_ actions: EpisodeActionViewModel) -> some View {
        Button {
            actions.toggleBookmark()
        } label: {
            Image(systemName: actions.isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: 16, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(.black)
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.92), in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: actions.isBookmarked) { _, saved in saved }
        .accessibilityLabel(actions.isBookmarked ? Text("Saved") : Text("Save"))
    }

    /// How far along, a mustard line along the bottom of the image.
    private func progressLine(_ progress: Double) -> some View {
        Rectangle()
            .fill(.white.opacity(0.35))
            .frame(height: 4)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Rectangle()
                        .fill(AppColor.Accent.soft)
                        .frame(width: proxy.size.width * min(max(progress, 0), 1))
                }
            }
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: Self.imageRadius, bottomTrailingRadius: Self.imageRadius, style: .continuous))
            .accessibilityHidden(true)
    }

    // MARK: - Footer

    private func footer(_ actions: EpisodeActionViewModel) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.episode.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Text(verbatim: "\(post.episode.pubDate.shortDayText()) · \(post.episode.durationDisplayText)")
                        .font(.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)

            Button {
                // A half-listened one starts where it was left.
                let isCurrent = PlayerManager.shared.currentEpisode?.streamUrl == post.episode.streamUrl
                if let progress = post.progress, !isCurrent {
                    PlayerManager.shared.play(post.episode, presentation: .mini, from: progress)
                } else {
                    actions.playOrPause()
                }
            } label: {
                Image(systemName: actions.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(AppColor.Text.onPastel)
                    .offset(x: actions.isPlaying ? 0 : 1)
                    .frame(width: 44, height: 44)
                    .background(AppColor.Accent.soft, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(actions.isPlaying ? Text("Pause") : Text("Play"))
        }
    }
}
