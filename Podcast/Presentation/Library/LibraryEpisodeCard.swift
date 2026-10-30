//
//  LibraryEpisodeCard.swift
//  Podcast
//

import SwiftUI

/// One episode in the Library, like an audio magazine's list: the square
/// cover centered on a band of its own color, the show in small monospaced
/// capitals, the title in serif, a line of what it's about, and the author
/// with ▶ length and •••.
struct LibraryEpisodeCard: View {

    let item: LibraryItem
    let onOpen: () -> Void

    /// The artwork's color; read once it loads (cached after that).
    @State private var loadedTint: ArtworkTint?

    private var tint: ArtworkTint? {
        loadedTint ?? ArtworkTintLoader.cachedTint(for: item.artwork)
    }

    var body: some View {
        let actions = EpisodeActionViewModel(episode: item.episode)

        VStack(alignment: .leading, spacing: 0) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 8) {
                    coverBand
                        .padding(.bottom, 6)

                    Text(item.showName)
                        .font(.system(.footnote, design: .monospaced, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(0.6)
                        .foregroundStyle(AppColor.Accent.strong)
                        .lineLimit(1)

                    Text(item.episode.title)
                        .font(.system(.title2, design: .serif))
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    if !item.episode.description.isEmpty {
                        Text(item.episode.description)
                            .font(.system(.body, design: .serif))
                            .foregroundStyle(AppColor.Text.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the episode")

            footer(actions)
                .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .task(id: item.artwork) {
            guard loadedTint == nil else { return }
            let tint = await ArtworkTintLoader.tint(for: item.artwork)
            withAnimation(.easeInOut(duration: 0.3)) { loadedTint = tint }
        }
    }

    /// The cover, small and centered, on a band of its own color.
    private var coverBand: some View {
        Rectangle()
            .fill(tint?.color ?? AppColor.Surface.muted)
            .frame(height: 200)
            .overlay {
                RowArtwork(side: 140) {
                    PodcastImage(source: item.artwork, contentMode: .fill)
                }
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .accessibilityHidden(true)
    }

    /// AUTHOR · ▶ 56m · •••
    private func footer(_ actions: EpisodeActionViewModel) -> some View {
        HStack(spacing: 4) {
            Text(item.episode.author)
                .font(.system(.footnote, design: .monospaced))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            DownloadedBadge(episode: item.episode)

            Button {
                actions.playOrPause()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: actions.isPlaying ? "pause.circle" : "play.circle")
                        .font(.title3)
                        .contentTransition(.symbolEffect(.replace))
                    Text(item.episode.durationDisplayText)
                        .font(.system(.subheadline, design: .monospaced))
                }
                .foregroundStyle(actions.isPlaying ? AppColor.Accent.strong : AppColor.Text.primary)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(actions.isPlaying ? Text("Pause") : Text("Play"))

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
}

/// Save, the download (by its state) and share, as menu items.
struct EpisodeActionsMenuItems: View {

    let actions: EpisodeActionViewModel

    var body: some View {
        Button(
            actions.isBookmarked ? LocalizedStringKey("Saved") : LocalizedStringKey("Save"),
            systemImage: actions.isBookmarked ? "bookmark.fill" : "bookmark"
        ) {
            actions.toggleBookmark()
        }

        switch actions.downloadState {
        case .idle:
            Button("Download", systemImage: "arrow.down.circle") { actions.download() }
        case .failed:
            Button("Retry download", systemImage: "arrow.clockwise.circle") { actions.download() }
        case .waiting, .downloading:
            Button("Cancel download", systemImage: "stop.circle") { actions.cancelDownload() }
        case .downloaded:
            Button("Remove download", systemImage: "trash", role: .destructive) { actions.deleteDownload() }
        }

        if let url = URL(string: actions.episode.streamUrl) {
            ShareLink(item: url, subject: Text(actions.episode.title)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}
