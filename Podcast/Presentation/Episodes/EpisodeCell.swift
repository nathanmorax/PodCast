//
//  EpisodeCell.swift
//  Podcast
//
//  Created by Xcaret Mora on 16/11/23.
//

import SwiftUI

/// One episode in a podcast's list, editorial style: the date as an overline
/// in violet, the title in serif, play + length; the artwork on the right
/// with the ••• menu under it.
struct EpisodeCell: View {
    let viewModel: EpisodeActionViewModel
    /// Opens the episode's details ("Details" in the ••• menu).
    var onInfo: (() -> Void)? = nil

    private var episode: Episode { viewModel.episode }

    /// "TODAY", "YESTERDAY", or "12 OCT".
    private var dateText: Text {
        let calendar = Calendar.current
        if calendar.isDateInToday(episode.pubDate) { return Text("Today") }
        if calendar.isDateInYesterday(episode.pubDate) { return Text("Yesterday") }
        return Text(episode.pubDate, format: .dateTime.day().month(.abbreviated))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                dateText
                    .font(AppFont.overline)
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(AppColor.Accent.strong)

                Text(episode.title)
                    .font(AppFont.editorialItem)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    Button {
                        viewModel.playOrPause()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 11, weight: .bold))
                            .contentTransition(.symbolEffect(.replace))
                            .foregroundStyle(AppColor.Accent.strong)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(AppColor.Accent.wash))
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.isPlaying ? Text("Pause") : Text("Play"))

                    Text(episode.durationDisplayText)
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // The episode's artwork, with the ••• menu under it (as before).
            VStack(alignment: .trailing, spacing: 0) {
                PodcastImage(source: episode.imageUrl)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityHidden(true)

                EpisodeContextMenuButton(viewModel: viewModel, onInfo: onInfo)
                    .frame(width: 36, height: 36)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
