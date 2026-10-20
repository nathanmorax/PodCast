//
//  RecentlyPlayedRow.swift
//  Podcast
//

import SwiftUI

/// "Recently played": the episodes you listened to, most recent first, as
/// covers with how far you got. Tap resumes where you left off; holding one
/// offers to open it or take it off the row.
/// The one playing now isn't here: it's already in the mini player.
struct RecentlyPlayedRow: View {

    let items: [RecentlyPlayed]
    let onResume: (RecentlyPlayed) -> Void
    let onOpen: (RecentlyPlayed) -> Void
    let onRemove: (RecentlyPlayed) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(items) { item in
                    Button {
                        onResume(item)
                    } label: {
                        RecentlyPlayedCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Play", systemImage: "play.fill") { onResume(item) }
                        Button("Episode details", systemImage: "text.alignleft") { onOpen(item) }
                        Button("Remove from recently played", systemImage: "minus.circle", role: .destructive) {
                            onRemove(item)
                        }
                    }
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}

/// Cover with a thin progress line at its foot, the title in serif and
/// what's left ("23 min left", or "Played").
private struct RecentlyPlayedCard: View {

    let item: RecentlyPlayed

    static let side: CGFloat = 140

    private var isFinished: Bool { item.progress >= 0.98 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .frame(width: Self.side, height: Self.side)
                .overlay { PodcastImage(source: item.episode.imageUrl) }
                .overlay(alignment: .bottom) { progressLine }
                .clipShape(RoundedRectangle(cornerRadius: LibraryCover.cornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.episode.title)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2, reservesSpace: true)
                Text(status)
                    .font(AppFont.caption)
                    .foregroundStyle(isFinished ? AppColor.Text.secondary : AppColor.Accent.strong)
                    .lineLimit(1)
            }
        }
        .frame(width: Self.side, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Resumes the episode")
    }

    /// Lavender over a dark track, on the cover's bottom edge.
    private var progressLine: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(AppColor.Accent.soft)
                .frame(width: proxy.size.width * item.progress)
        }
        .frame(height: 4)
        .background(.black.opacity(0.35))
        .opacity(item.progress > 0 ? 1 : 0)
        .accessibilityHidden(true)
    }

    /// "23 min left" while in the middle; "Played" once finished.
    private var status: String {
        if isFinished { return String(localized: "Played") }
        guard let total = item.episode.durationSeconds, item.progress > 0 else {
            return item.episode.durationDisplayText
        }
        let minutes = max(1, Int(((1 - item.progress) * total / 60).rounded(.up)))
        return String(localized: "\(minutes) min left")
    }
}

#Preview {
    RecentlyPlayedRow(
        items: Episode.mocks.enumerated().map { offset, episode in
            RecentlyPlayed(episode: episode, lastPlayedAt: .now, progress: Double(offset) * 0.3)
        },
        onResume: { _ in },
        onOpen: { _ in },
        onRemove: { _ in }
    )
}
