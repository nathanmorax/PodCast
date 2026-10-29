//
//  LibraryCovers.swift
//  Podcast
//

import SwiftUI

/// The podcasts you follow, as square covers (corners rounded 8) with their
/// name under them. Each cover is what its podcast's page zooms out of and
/// back into. A show with new episodes has them peeking out from behind
/// its cover (PeekingCover).
struct LibraryCovers: View {

    let podcasts: [Podcast]
    /// trackId → its new episodes, newest first (NewEpisodeMarks).
    var newEpisodes: [Int: [Episode]] = [:]
    let onOpen: (Podcast) -> Void
    /// The last tile, "See All": only when the covers don't all fit.
    let onSeeAll: () -> Void

    private static let spacing: CGFloat = 8
    private static let margin: CGFloat = 20

    /// The row's visible width.
    @State private var visibleWidth: CGFloat = 0

    /// The covers alone (without the See All tile, so adding it can't
    /// change the answer) are wider than the screen: some are out of view.
    private var overflows: Bool {
        let count = CGFloat(podcasts.count)
        let coversWidth = count * Self.side + max(count - 1, 0) * Self.spacing + Self.margin * 2
        return visibleWidth > 0 && coversWidth > visibleWidth
    }

    static let side: CGFloat = 68
    static let cornerRadius: CGFloat = 4

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: Self.spacing) {
                ForEach(podcasts, id: \.trackId) { podcast in
                    Button {
                        onOpen(podcast)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            // The cards peeking out say it's new; no text needed.
                            PeekingCover(
                                podcast: podcast,
                                newEpisodes: newEpisodes[podcast.trackId] ?? [],
                                side: Self.side,
                                cornerRadius: Self.cornerRadius
                            )
                            Text(podcast.trackName ?? "")
                                .font(AppFont.feedSmall)
                                .textCase(.uppercase)
                                .foregroundStyle(AppColor.Text.primary)
                                .lineLimit(1)
                        }
                        .frame(width: Self.side, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(podcast.trackName ?? ""))
                    .accessibilityValue(newValue(for: podcast))
                }

                if overflows {
                    seeAllTile
                }
            }
            // Room above the covers for the cards that peek out.
            .padding(.top, 16)
        }
        .contentMargins(.horizontal, Self.margin, for: .scrollContent)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.containerSize.width
        } action: { _, width in
            visibleWidth = width
        }
    }

    private func newValue(for podcast: Podcast) -> Text {
        let count = newEpisodes[podcast.trackId]?.count ?? 0
        return count > 0 ? Text("\(count) new episodes") : Text(verbatim: "")
    }

    /// At the end of the row, the size of a cover: → and "See All".
    private var seeAllTile: some View {
        Button(action: onSeeAll) {
            VStack(spacing: 6) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(AppColor.Text.primary.opacity(0.1)))
                Text("See All")
                    .font(AppFont.captionStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(AppColor.Text.primary)
            .frame(width: Self.side, height: Self.side)
            .background(
                RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                    .fill(AppColor.Surface.muted)
            )
            .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
