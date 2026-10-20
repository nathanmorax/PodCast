//
//  PodcastAboutSheet.swift
//  Podcast
//

import SwiftUI

/// "About this podcast", from the ⓘ next to the header's description.
struct PodcastAboutSheet: View {

    let podcast: Podcast
    let description: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    PodcastImage(source: podcast.artworkUrl600)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(podcast.trackName ?? "")
                            .font(AppFont.sectionTitle)
                            .foregroundStyle(AppColor.ink)
                        Text(podcast.artistName ?? "")
                            .font(AppFont.body)
                            .foregroundStyle(AppColor.Text.secondary)
                    }
                }
                .padding(.top, 8)

                Text("About this podcast")
                    .overlineStyle()

                Text(description)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.ink.opacity(0.85))
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
        .background(AppColor.paper.ignoresSafeArea())
    }
}

#Preview {
    PodcastAboutSheet(podcast: .mock, description: "A show about everything.")
}
