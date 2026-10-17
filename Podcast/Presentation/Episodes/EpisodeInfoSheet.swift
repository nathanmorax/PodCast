//
//  EpisodeInfoSheet.swift
//  Podcast
//

import SwiftUI

/// An episode's details, opened from the ⓘ in its row: artwork, title,
/// date and length, a Listen button and the full show notes.
struct EpisodeInfoSheet: View {

    let episode: Episode
    let onPlay: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var notes: String {
        let full = episode.showNotes ?? ""
        return full.isEmpty ? episode.description : full
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    PodcastImage(source: episode.imageUrl)
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(episode.title)
                            .font(AppFont.sheetTitle)
                            .foregroundStyle(AppColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 6) {
                            Text(episode.pubDate, format: .dateTime.day().month(.wide).year())
                            Text(verbatim: "·")
                            Text(episode.durationDisplayText)
                        }
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                    }
                }
                .padding(.top, 8)

                Button(action: onPlay) {
                    Label("Listen to episode", systemImage: "play.fill")
                        .font(AppFont.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Capsule().fill(AppColor.Accent.strong))
                }
                .buttonStyle(.plain)

                if !notes.isEmpty {
                    Text(notes)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.ink.opacity(0.8))
                        .lineSpacing(3)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .background(AppColor.paper.ignoresSafeArea())
    }
}

#Preview {
    EpisodeInfoSheet(episode: .mock, onPlay: {})
}
