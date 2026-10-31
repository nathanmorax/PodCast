//
//  YourPodcastsRow.swift
//  Podcast
//

import SwiftUI

/// The podcasts you follow, side by side: a big rounded cover, its name
/// and who makes it. New episodes peek out from behind the cover
/// (PeekingCover), and those shows come first. Each cover is what its podcast's page zooms out of. When the
/// covers don't all fit, the row ends with a See All tile (Following).
struct YourPodcastsRow: View {

    let podcasts: [Podcast]
    /// trackId → its new episodes (NewEpisodeMarks).
    var newEpisodes: [Int: [Episode]] = [:]
    let onOpen: (Podcast) -> Void
    let onSeeAll: () -> Void

    private static let spacing: CGFloat = 8
    private static let margin: CGFloat = 20

    /// The row's visible width.
    @State private var visibleWidth: CGFloat = 0

    /// The covers alone (without the tile, so adding it can't change the
    /// answer) are wider than the screen.
    private var overflows: Bool {
        let count = CGFloat(podcasts.count)
        let width = count * Self.side + max(count - 1, 0) * Self.spacing + Self.margin * 2
        return visibleWidth > 0 && width > visibleWidth
    }

    static let side: CGFloat = 70
    static let cornerRadius: CGFloat = 8

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: Self.spacing) {
                ForEach(podcasts, id: \.trackId) { podcast in
                    Button {
                        onOpen(podcast)
                    } label: {
                        card(podcast)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
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
        // The last cover in view dissolves at the edge: there are more.
        .trailingFade()
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.containerSize.width
        } action: { _, width in
            visibleWidth = width
        }
    }

    /// The last tile, the size of a cover: → and "See All".
    private var seeAllTile: some View {
        Button(action: onSeeAll) {
            VStack(spacing: 10) {
                Text("See All")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)
            }
            .frame(width: Self.side, height: Self.side)
        }
        .buttonStyle(.plain)
    }

    private func card(_ podcast: Podcast) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // New episodes peek out from behind the cover (no text needed).
            PeekingCover(
                podcast: podcast,
                newEpisodes: newEpisodes[podcast.trackId] ?? [],
                side: Self.side,
                cornerRadius: Self.cornerRadius
            )
            .padding(.bottom, 8)

        }
        .frame(width: Self.side, alignment: .leading)
        .contentShape(Rectangle())
    }



    private func newValue(for podcast: Podcast) -> Text {
        let count = newEpisodes[podcast.trackId]?.count ?? 0
        return count > 0 ? Text("\(count) new episodes") : Text(verbatim: "")
    }
}
