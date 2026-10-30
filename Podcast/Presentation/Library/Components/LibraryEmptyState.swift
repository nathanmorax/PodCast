//
//  LibraryEmptyState.swift
//  Podcast
//

import SwiftUI

/// What an empty Library tab says, and how it fills up.
struct LibraryEmptyState: View {

    let tab: LibraryTab

    var body: some View {
        switch tab {
        case .new:
            ContentUnavailableView(
                "No new episodes",
                systemImage: "tray",
                description: Text("New episodes from the podcasts you follow show up here.")
            )
        case .saved:
            ContentUnavailableView(
                "No saved episodes",
                systemImage: "bookmark",
                description: Text("Touch and hold an episode to save it, and it'll be here.")
            )
        case .downloads:
            ContentUnavailableView(
                "No downloads yet",
                systemImage: "arrow.down.circle",
                description: Text("Downloaded episodes play without internet.")
            )
        case .history:
            ContentUnavailableView(
                "Nothing played yet",
                systemImage: "clock.arrow.circlepath",
                description: Text("Episodes you play show up here.")
            )
        }
    }
}
