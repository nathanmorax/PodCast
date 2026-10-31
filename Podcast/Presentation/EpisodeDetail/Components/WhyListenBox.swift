//
//  WhyListenBox.swift
//  Podcast
//

import SwiftUI

/// The first sentence of the notes in a soft rounded box: why this
/// episode is worth it.
struct WhyListenBox: View {

    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            EpisodeSectionTitle(title: "Why listen")
            Text(text)
                .font(.body)
                .foregroundStyle(AppColor.Text.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(AppColor.Text.primary)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.Surface.muted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
