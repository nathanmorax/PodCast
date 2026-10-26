//
//  DownloadedBadge.swift
//  Podcast
//

import SwiftUI

/// ↓ in a filled circle, in the accent, next to an episode's length: it's
/// on the phone and plays without internet. Shows only for downloaded
/// episodes (nothing at all otherwise), wherever an episode is listed.
struct DownloadedBadge: View {

    let episode: Episode

    @Environment(\.downloadManager) private var downloads

    private var isDownloaded: Bool {
        if case .downloaded = downloads.state(for: episode) { return true }
        return false
    }

    var body: some View {
        if isDownloaded {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColor.Accent.strong)
                .accessibilityLabel(Text("Downloaded"))
                .transition(.scale.combined(with: .opacity))
        }
    }
}
