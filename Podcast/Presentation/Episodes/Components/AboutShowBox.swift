//
//  AboutShowBox.swift
//  Podcast
//

import SwiftUI

/// The show's description in a box with an ink border (like the episode's
/// "Why listen"), three lines of it; "Read more" opens it whole.
struct AboutShowBox: View {

    let description: String
    let onReadMore: () -> Void

    var body: some View {
        Button(action: onReadMore) {
            VStack(alignment: .leading, spacing: 8) {
                EpisodeSectionTitle(title: "About the show")
                Text(description)
                    .font(.body)
                    .lineSpacing(3)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Text("Read more")
                    .font(.footnote.weight(.bold))
            }
            .foregroundStyle(AppColor.Text.primary)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay {
                Rectangle().strokeBorder(AppColor.Text.primary, lineWidth: 1.5)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows the full description")
    }
}
