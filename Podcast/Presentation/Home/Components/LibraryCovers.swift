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

    static let side: CGFloat = 96
    static let cornerRadius: CGFloat = 8

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 16) {
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
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .scrollIndicators(.hidden)
    }
}

#Preview {
    LibraryCovers(podcasts: [.mock], onOpen: { _ in })
}
