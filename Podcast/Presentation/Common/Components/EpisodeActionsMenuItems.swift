//
//  EpisodeActionsMenuItems.swift
//  Podcast
//

import SwiftUI

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
