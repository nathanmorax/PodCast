//
//  ChaptersSection.swift
//  Podcast
//

import SwiftUI

/// The chapters written in the show notes: time and title, the one playing
/// in mustard and bold. Tapping one jumps there (or starts the episode
/// there).
struct ChaptersSection: View {

    let chapters: [EpisodeChapter]
    /// The chapter being played (nil: the episode isn't in the player).
    let current: EpisodeChapter?
    let onSelect: (EpisodeChapter) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            EpisodeSectionTitle(title: "Chapters")
                .padding(.bottom, 4)

            ForEach(chapters) { chapter in
                let isCurrent = chapter.id == current?.id
                Button {
                    onSelect(chapter)
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Text(AVPlayerViewModel.shortTime(chapter.start))
                            .font(.footnote.weight(isCurrent ? .bold : .regular))
                            .monospacedDigit()
                            .foregroundStyle(isCurrent ? AppColor.Accent.strong : AppColor.Text.secondary)
                            .frame(minWidth: 48, alignment: .leading)
                        Text(chapter.title)
                            .font(.body.weight(isCurrent ? .bold : .regular))
                            .foregroundStyle(AppColor.Text.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 10)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isCurrent ? .isSelected : [])
                .overlay(alignment: .bottom) {
                    if chapter.id != chapters.last?.id {
                        Rectangle()
                            .fill(AppColor.Text.primary.opacity(0.08))
                            .frame(height: 1)
                    }
                }
            }
        }
        .animation(AppAnimation.selection, value: current?.id)
    }
}
