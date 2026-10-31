//
//  StatusOverlay.swift
//  Podcast
//

import SwiftUI

/// The status pill over every screen, floating under the navigation bar,
/// centered. It appears when something happens (downloading, offline,
/// updating, a download done or failed) and confirms what you just did
/// (saved or not, followed or not, a download removed, an episode out of
/// the history), then slides away.
/// It never takes touches: the screen under it stays usable.
struct StatusOverlay: View {

    @Environment(\.downloadManager) private var downloads
    @Environment(\.playerManager) private var player
    @Environment(\.bookmarks) private var bookmarks
    @Environment(\.favoritesManager) private var favorites
    @Environment(\.recentlyPlayed) private var recentlyPlayed

    private var network: NetworkMonitor { .shared }
    private var center: StatusCenter { .shared }

    /// Below the navigation bar.
    private static let topOffset: CGFloat = 52

    private var states: [DownloadState] { Array(downloads.states.values) }

    private var status: AppStatus? {
        AppStatusResolver.resolve(
            isOffline: network.isOffline,
            downloads: AppStatusResolver.downloadProgress(states),
            isUpdating: center.isUpdating,
            flash: center.flash
        )
    }

    private var finishedCount: Int {
        states.filter { if case .downloaded = $0 { true } else { false } }.count
    }

    private var failedCount: Int {
        states.filter { if case .failed = $0 { true } else { false } }.count
    }

    var body: some View {
        ZStack {
            // Not over the full player: it has its own screen.
            if let status, player.presentation != .expanded {
                StatusPill(status: status)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .id(statusKind(status))
            }
        }
        .padding(.top, Self.topOffset)
        .frame(maxWidth: .infinity, alignment: .top)
        .animation(.spring(duration: 0.4, bounce: 0.2), value: status.map(statusKind))
        .allowsHitTesting(false)
        // A download that just finished or failed: say so for a moment.
        .onChange(of: finishedCount) { old, new in
            if new > old { center.flash(.downloaded) }
        }
        .onChange(of: failedCount) { old, new in
            if new > old { center.flash(.failed) }
        }
        // What you just did, wherever you did it (a button, a menu, a list):
        // the lists grew or shrank.
        .onChange(of: bookmarks.episodes.count) { old, new in
            center.flash(new > old ? .saved : .unsaved)
        }
        .onChange(of: favorites.favorites.count) { old, new in
            center.flash(new > old ? .followed : .unfollowed)
        }
        .onChange(of: downloads.downloadedEpisodes.count) { old, new in
            if new < old { center.flash(.downloadRemoved) }
        }
        .onChange(of: recentlyPlayed.items.count) { old, new in
            if new < old { center.flash(.removedFromHistory) }
        }
    }

    /// Changes only when the kind changes (not with every bit of progress),
    /// so the pill animates in and out, not on each update.
    private func statusKind(_ status: AppStatus) -> String {
        switch status {
        case .downloading: "downloading"
        case .updating: "updating"
        case .offline: "offline"
        case .downloaded: "downloaded"
        case .failed: "failed"
        case .saved: "saved"
        case .unsaved: "unsaved"
        case .followed: "followed"
        case .unfollowed: "unfollowed"
        case .downloadRemoved: "downloadRemoved"
        case .downloadCanceled: "downloadCanceled"
        case .removedFromHistory: "removedFromHistory"
        }
    }
}
