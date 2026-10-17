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
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(AppColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 6) {
                            Text(episode.pubDate, format: .dateTime.day().month(.wide).year())
                            Text(verbatim: "·")
                            Text(episode.durationDisplayText)
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)

                Button(action: onPlay) {
                    Label("Listen to episode", systemImage: "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Capsule().fill(AppColor.ink))
                }
                .buttonStyle(.plain)

                if !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 15))
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
