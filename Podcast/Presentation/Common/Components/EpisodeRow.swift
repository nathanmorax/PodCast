//
//  EpisodeRow.swift
//  Podcast
//

import SwiftUI

/// One episode in any list (a podcast's page, Favorites, Downloads): the
/// EpisodeCell on the page itself, no card, with a hairline separator under
/// it (inset like iOS lists). Tapping it opens its details; only its play
/// button and ••• menu keep their own taps.
struct EpisodeRow: View {

    let episode: Episode
    let showsSeparator: Bool
    let onShowInfo: () -> Void

    /// For a true one-pixel hairline on any screen.
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        EpisodeCell(viewModel: EpisodeActionViewModel(episode: episode), onInfo: onShowInfo)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .overlay(alignment: .bottom) {
                if showsSeparator {
                    Rectangle()
                        .fill(AppColor.Text.tertiary.opacity(0.5))
                        .frame(height: 1 / displayScale)
                        .padding(.horizontal, 24)
                }
            }
            .contentShape(Rectangle())
            // The play button and the ••• menu inside keep their own taps.
            .onTapGesture(perform: onShowInfo)
            .accessibilityAction(named: Text("Details"), onShowInfo)
    }
}
