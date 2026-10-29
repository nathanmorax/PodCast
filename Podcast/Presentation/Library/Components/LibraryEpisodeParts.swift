//
//  LibraryEpisodeParts.swift
//  Podcast
//

import SwiftUI

/// "OCT 14 · 48 MIN ↓" in small capitals (only the length when there's
/// little room). In the accent while it plays.
struct LibraryEpisodeMeta: View {

    let episode: Episode
    var isPlaying = false
    var showsDate = true

    var body: some View {
        HStack(spacing: 5) {
            if showsDate {
                Text(episode.pubDate, format: .dateTime.day().month(.abbreviated))
                Text(verbatim: "·")
            }
            Text(episode.durationDisplayText)
            DownloadedBadge(episode: episode)
        }
        .font(.caption2.weight(.bold))
        .textCase(.uppercase)
        .tracking(0.8)
        .foregroundStyle(isPlaying ? AppColor.Accent.strong : AppColor.Text.secondary)
        .lineLimit(1)
    }
}

/// ▶ / ❚❚ for one episode, in the mini player. Two looks:
/// - `outline`: a thin ring next to a line (like the podcast page's rows);
/// - `onCover`: a small dark circle on a cover's corner.
/// Both keep a 44 pt touch area.
struct LibraryPlayButton: View {

    enum Style {
        case outline
        case onCover
    }

    let actions: EpisodeActionViewModel
    var style: Style = .outline

    var body: some View {
        Button {
            actions.playOrPause()
        } label: {
            switch style {
            case .outline:
                glyph(size: 13, color: actions.isPlaying ? AppColor.Accent.strong : AppColor.Text.primary)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle().strokeBorder(
                            actions.isPlaying ? AppColor.Accent.strong : AppColor.Text.primary.opacity(0.3),
                            lineWidth: 1
                        )
                    }
                    .contentShape(Circle())
            case .onCover:
                glyph(size: 10, color: .white)
                    .frame(width: 30, height: 30)
                    .background(.black.opacity(0.6), in: Circle())
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(actions.isPlaying ? Text("Pause") : Text("Play"))
    }

    private func glyph(size: CGFloat, color: Color) -> some View {
        Image(systemName: actions.isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: size, weight: .bold))
            .contentTransition(.symbolEffect(.replace))
            .foregroundStyle(color)
            // ▶ looks off-center by a point; ❚❚ doesn't.
            .offset(x: actions.isPlaying ? 0 : 1)
    }
}
