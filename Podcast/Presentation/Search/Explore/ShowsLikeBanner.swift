//
//  ShowsLikeBanner.swift
//  Podcast
//

import SwiftUI

/// On top of Search: "SHOWS LIKE FIELD NOTES", over the cover of a show
/// you follow (the one you followed last), full width under a dark fade.
/// Opens that show's category.
struct ShowsLikeBanner: View {

    let podcast: Podcast
    let genreName: String
    let onOpen: () -> Void

    static let height: CGFloat = 170

    var body: some View {
        Button(action: onOpen) {
            ZStack(alignment: .bottomLeading) {
                Color.clear
                    .overlay { PodcastImage(source: podcast.artworkUrl600) }
                    .clipped()

                LinearGradient(
                    stops: [.init(color: .black.opacity(0.15), location: 0), .init(color: .black.opacity(0.78), location: 1)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("For you · \(genreName)")
                        .font(.caption2.weight(.heavy))
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.white)

                    Text("Shows like \(podcast.trackName ?? "")")
                        .font(AppFont.feedTitle)
                        .textCase(.uppercase)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }
            .frame(height: Self.height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the category")
    }
}
