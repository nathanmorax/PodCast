//
//  EpisodeCell.swift
//  Podcast
//
//  Created by Xcaret Mora on 16/11/23.
//

import UIKit
import SwiftUI

struct EpisodeCell: View {
    let viewModel: EpisodeActionViewModel
    /// Opens the episode's details ("Details" in the ••• menu).
    var onInfo: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.episode.pubDate, style: .date)
                    .foregroundStyle(AppColor.Accent.strong)
                    .font(AppFont.footnote)

                Text(viewModel.episode.title)
                    .font(AppFont.headline)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)

                Text(viewModel.episode.description)
                    .font(AppFont.callout)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(2)

                Spacer()

                Button {
                    viewModel.playOrPause()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text(viewModel.episode.durationDisplayText)
                            .font(AppFont.captionStrong)
                    }
                    .foregroundStyle(AppColor.Accent.strong)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Capsule().fill(AppColor.Accent.wash))
                }
                .buttonStyle(.plain)
            }
            .frame(maxHeight: .infinity)

            VStack(alignment: .trailing, spacing: 0) {
                PodcastImage(source: viewModel.episode.imageUrl)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                EpisodeContextMenuButton(viewModel: viewModel, onInfo: onInfo)
                    .frame(width: 36, height: 36)
            }
        }
        // Full width; the height is whatever the content needs.
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .onAppear {
            PerformanceLogger.rendering.event("EpisodeCellUI appeared", "title: \(viewModel.episode.title)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
