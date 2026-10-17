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
    /// Opens the episode's details (the ⓘ button). Nil hides the button.
    var onInfo: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.episode.pubDate, style: .date)
                    .foregroundStyle(AppColor.dustyBlue)
                    .font(.system(size: 13, weight: .medium))

                Text(viewModel.episode.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(viewModel.episode.description)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer()

                Button {
                    viewModel.playOrPause()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text(viewModel.episode.durationDisplayText)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            .frame(maxHeight: .infinity)

            VStack(alignment: .trailing, spacing: 0) {
                PodcastImage(source: viewModel.episode.imageUrl)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                HStack(spacing: 0) {
                    if let onInfo {
                        Button(action: onInfo) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Episode details")
                    }
                    EpisodeContextMenuButton(viewModel: viewModel)
                        .frame(width: 36, height: 36)
                }
            }
        }
        // The row has a fixed height (EpisodesController.Layout.cellHeight);
        // fixed font sizes and line limits keep the content inside it.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            PerformanceLogger.rendering.event("EpisodeCellUI appeared", "title: \(viewModel.episode.title)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
