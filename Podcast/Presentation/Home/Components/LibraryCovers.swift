//
//  LibraryCovers.swift
//  Podcast
//

import SwiftUI

/// The podcasts you follow, as square covers (corners rounded 8) with their
/// name under them. Each cover is what its podcast's page zooms out of and
/// back into.
struct LibraryCovers: View {

    let podcasts: [Podcast]
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

    static let side: CGFloat = 80
    static let cornerRadius: CGFloat = 8

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: Self.spacing) {
                ForEach(podcasts, id: \.trackId) { podcast in
                    Button {
                        onOpen(podcast)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Color.clear
                                .frame(width: Self.side, height: Self.side)
                                .overlay { ZoomSourceImage(podcast: podcast, cornerRadius: Self.cornerRadius) }
                                .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
                                .accessibilityHidden(true)
//                            Text(podcast.trackName ?? "")
//                                .font(AppFont.label)
//                                .foregroundStyle(AppColor.Text.primary)
//                                .lineLimit(2, reservesSpace: true)
                        }
                        .frame(width: Self.side, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                if overflows {
                    seeAllTile
                }
            }
        }
        .contentMargins(.horizontal, Self.margin, for: .scrollContent)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.containerSize.width
        } action: { _, width in
            visibleWidth = width
        }
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
