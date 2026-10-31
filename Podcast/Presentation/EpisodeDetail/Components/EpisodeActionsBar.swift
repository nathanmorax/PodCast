//
//  EpisodeActionsBar.swift
//  Podcast
//

import SwiftUI

/// Centered under the title: ▶ Listen (filled in the accent) and save,
/// download and share in soft circles.
struct EpisodeActionsBar: View {

    let actions: EpisodeActionViewModel
    let onListen: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onListen) {
                Label(actions.isPlaying ? "Pause" : "Listen",
                      systemImage: actions.isPlaying ? "pause.fill" : "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(AppColor.Text.inverse)
                    .padding(.horizontal, 26)
                    .frame(minHeight: 44)
                    .background(AppColor.Accent.strong, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)

            EpisodeSaveButton(actions: actions)
            EpisodeDownloadButton(actions: actions)

            if let url = URL(string: actions.episode.streamUrl) {
                ShareLink(item: url, subject: Text(actions.episode.title)) {
                    EpisodeActionIcon {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share")
            }
        }
        .frame(maxWidth: .infinity)
    }
}
