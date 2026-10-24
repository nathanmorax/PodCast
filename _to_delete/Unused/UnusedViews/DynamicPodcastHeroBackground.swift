//
//  DynamicPodcastHeroBackground.swift
//  Podcast
//

import SwiftUI

struct DynamicPodcastHeroBackground: View {
    let imageURL: String?

    var body: some View {
        ZStack {
            PodcastImage(source: imageURL)
                .scaledToFill()
                .blur(radius: 55)
                .scaleEffect(1.5)
                .saturation(1.5)
                .brightness(-0.08)

            LinearGradient(
                colors: [.black.opacity(0.1), .clear, .black.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipped()
    }
}
