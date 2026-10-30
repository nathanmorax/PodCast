//
//  DownloadProgressLine.swift
//  Podcast
//

import SwiftUI

/// While an episode downloads, a hairline that fills in mustard: no ring,
/// no percentage, just how far along it is. Nothing at all otherwise (it
/// fades out once the file is on the phone, and ↓ takes over).
/// Goes under a title or along the bottom of a cover.
struct DownloadProgressLine: View {

    let episode: Episode
    /// The unfilled part (darker on a cover).
    var track: Color = AppColor.Text.primary.opacity(0.12)

    @Environment(\.downloadManager) private var downloads

    /// 0…1 while waiting or downloading; nil otherwise.
    private var progress: Double? {
        switch downloads.state(for: episode) {
        case .waiting:
            return 0
        case .downloading(let progress):
            return min(max(progress, 0), 1)
        case .idle, .downloaded, .failed:
            return nil
        }
    }

    var body: some View {
        if let progress {
            Rectangle()
                .fill(track)
                .frame(height: 2)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Rectangle()
                            .fill(AppColor.Accent.soft)
                            // A sliver even at 0, so it reads as started.
                            .frame(width: proxy.size.width * max(progress, 0.03))
                    }
                }
                .clipped()
                .animation(.easeOut(duration: 0.3), value: progress)
                .transition(.opacity)
                .accessibilityElement()
                .accessibilityLabel(Text("Downloading"))
                .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
        }
    }
}
