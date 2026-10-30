//
//  EpisodeActionsBar.swift
//  Podcast
//

import SwiftUI

/// Listen (mustard capsule) on the left; save, download and share as icons
/// on the right.
struct EpisodeActionsBar: View {

    let actions: EpisodeActionViewModel
    let onListen: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onListen) {
                Label(actions.isPlaying ? "Pause" : "Listen",
                      systemImage: actions.isPlaying ? "pause.fill" : "play.fill")
                    .font(.subheadline.weight(.bold))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(AppColor.Text.onPastel)
                    .padding(.horizontal, 24)
                    .frame(minHeight: 46)
                    .background(Capsule().fill(AppColor.Accent.soft))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

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
    }
}
