//
//  WhyListenBox.swift
//  Podcast
//

import SwiftUI

/// The first sentence of the notes in a box with an ink border, like a film
/// page's "Our take": why this episode is worth it.
struct WhyListenBox: View {

    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EpisodeSectionTitle(title: "Why listen")
            Text(text)
                .font(.body)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(AppColor.Text.primary)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            Rectangle().strokeBorder(AppColor.Text.primary, lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
    }
}
