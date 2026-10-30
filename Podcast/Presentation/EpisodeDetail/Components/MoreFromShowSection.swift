//
//  MoreFromShowSection.swift
//  Podcast
//

import SwiftUI

/// The page's last block, dark in both modes (like a film page's awards):
/// the show's other latest episodes, each with its date, length and ▶.
/// Tapping a row opens that episode; ▶ plays it in the mini player.
struct MoreFromShowSection: View {

    let showName: String
    let episodes: [Episode]
    let onOpen: (Episode) -> Void
    let onPlay: (Episode) -> Void

    /// Its own colors: the same dark block in light and dark mode.
    private static let background = Color(red: 0.086, green: 0.086, blue: 0.078)
    private static let text = Color(red: 0.95, green: 0.94, blue: 0.91)

    @Environment(\.playerManager) private var playerManager

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("More from \(showName)")
                .font(.caption.weight(.heavy))
                .textCase(.uppercase)
                .tracking(1)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 8)

            ForEach(episodes, id: \.streamUrl) { episode in
                row(episode)
                if episode.streamUrl != episodes.last?.streamUrl {
                    Rectangle()
                        .fill(Self.text.opacity(0.1))
                        .frame(height: 1)
                }
            }
        }
        .foregroundStyle(Self.text)
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.background)
        .environment(\.colorScheme, .dark)
    }

    private func row(_ episode: Episode) -> some View {
        let isPlaying = playerManager.currentEpisode?.streamUrl == episode.streamUrl
            && playerManager.viewModel.isPlaying
        return HStack(spacing: 14) {
            Button {
                onOpen(episode)
            } label: {
                HStack(spacing: 14) {
                    PodcastImage(source: episode.imageUrl, contentMode: .fill)
                        .frame(width: 52, height: 52)
                        .clipped()
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(episode.title)
                            .font(.system(.headline, weight: .semibold).width(.compressed))
                            .textCase(.uppercase)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: 4) {
                            Text(episode.pubDate, format: .dateTime.day().month(.abbreviated))
                            Text(verbatim: "·")
                            Text(episode.durationDisplayText)
                        }
                        .font(.caption)
                        .opacity(0.6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens the episode")

            Button {
                onPlay(episode)
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 16, height: 16)
                    .offset(x: isPlaying ? 0 : 1)
                    .frame(width: 44, height: 44)
                    .overlay { Circle().strokeBorder(Self.text.opacity(0.3), lineWidth: 1) }
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? Text("Pause") : Text("Play"))
        }
        .padding(.vertical, 8)
    }
}
