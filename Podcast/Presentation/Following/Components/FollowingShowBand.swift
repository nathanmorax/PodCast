//
//  FollowingShowBand.swift
//  Podcast
//

import SwiftUI

/// One show you follow, as a band in its own color (read from its cover):
/// the cover, its name in tall white capitals with "3 NEW", and its newest
/// episode ("LATEST · TUE" and the title). The band opens the show; ▶
/// plays that newest episode right there.
struct FollowingShowBand: View {

    let show: FollowingShow
    let onOpen: () -> Void

    /// The cover's color; read once it loads (cached after that).
    @State private var loadedTint: ArtworkTint?

    private var artwork: String? { show.podcast.artworkUrl600 }

    private var tint: ArtworkTint? {
        loadedTint ?? ArtworkTintLoader.cachedTint(for: artwork)
    }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onOpen) {
                HStack(spacing: 14) {
                    Color.clear
                        .frame(width: 72, height: 72)
                        .overlay { ZoomSourceImage(podcast: show.podcast, cornerRadius: 0) }
                        .clipped()
                        .shadow(color: .black.opacity(0.3), radius: 7, y: 4)
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
        .padding(.leading, 20)
        .padding(.trailing, 16)
        .padding(.vertical, 14)
        .foregroundStyle(.white)
        .background {
            // A light scrim keeps the white text readable on pale covers.
            ZStack {
                tint?.color ?? Color(white: 0.22)
                Color.black.opacity(0.22)
            }
        }
        .task(id: artwork) {
            guard loadedTint == nil else { return }
            let tint = await ArtworkTintLoader.tint(for: artwork)
            withAnimation(AppAnimation.stateChange) { loadedTint = tint }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(show.podcast.trackName ?? "")
                    .font(.system(.title3, weight: .bold).width(.compressed))
                    .textCase(.uppercase)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if show.newCount > 0 {
                    Text("\(show.newCount) new")
                        .font(.caption2.weight(.heavy))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(AppColor.Text.onPastel)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppColor.Accent.soft)
                        .fixedSize()
                }
            }

            if let latest = show.latest {
                Text("Latest · \(latest.pubDate.shortDayText())")
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .opacity(0.75)
                    .padding(.top, 2)
                Text(latest.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            } else if let artist = show.podcast.artistName, !artist.isEmpty {
                Text(artist)
                    .font(.subheadline)
                    .opacity(0.8)
                    .lineLimit(1)
            }
        }
    }
}

/// ▶ / ❚❚ for a show's newest episode, in a dark circle on its band.
private struct PlayLatestButton: View {

    let episode: Episode

    var body: some View {
        let actions = EpisodeActionViewModel(episode: episode)
        Button {
            actions.playOrPause()
        } label: {
            Image(systemName: actions.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 14, weight: .bold))
                .contentTransition(.symbolEffect(.replace))
                .offset(x: actions.isPlaying ? 0 : 1)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.35), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(actions.isPlaying ? Text("Pause") : Text("Play latest episode"))
    }
}
