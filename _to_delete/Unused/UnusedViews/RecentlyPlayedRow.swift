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

/// Cover, the title in serif, and a mustard capsule with play, a small bar
/// filled up to where you left off, and the minutes still to go ("23 min").
private struct RecentlyPlayedCard: View {

    let item: RecentlyPlayed

    static let side: CGFloat = 140

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color.clear
                .frame(width: Self.side, height: Self.side)
                .overlay {
                    ZoomSourceImage(
                        id: .episode(item.episode.streamUrl, section: .recentlyPlayed),
                        source: item.artworkSource,
                        cornerRadius: LibraryCover.cornerRadius
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: LibraryCover.cornerRadius, style: .continuous))

            Text(item.episode.title)
                .font(AppFont.cardTitle)
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(2, reservesSpace: true)

            ResumeCapsule(progress: item.progress, minutes: item.minutesLeftText)
        }
        .frame(width: Self.side, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Resumes the episode")
    }
}

/// ▶ ━━━━──── 23 min, like the play pill of an episode row, with the bar
/// painted up to where the listener stopped.
private struct ResumeCapsule: View {

    let progress: Double
    let minutes: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "play.fill")
                .font(.system(size: 9, weight: .bold))
                .accessibilityHidden(true)

            Capsule()
                .fill(AppColor.Accent.strong.opacity(0.2))
                .frame(height: 3)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(AppColor.Accent.strong)
                        .scaleEffect(x: min(max(progress, 0), 1), y: 1, anchor: .leading)
                }
                .clipShape(Capsule())
                .accessibilityHidden(true)

            Text(minutes)
                .font(AppFont.captionStrong)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
        }
        .foregroundStyle(AppColor.Accent.strong)
        .padding(.horizontal, 10)
        .frame(height: 26)
        .background(AppColor.Accent.wash, in: .capsule)
    }
}
