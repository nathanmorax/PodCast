//
//  AboutShowBox.swift
//  Podcast
//

import SwiftUI

/// "About" and three lines of the description in a soft rounded box;
/// "More" opens the whole of it in a sheet.
struct AboutShowBox: View {

    let description: String
    let onReadMore: () -> Void

    var body: some View {
        Button(action: onReadMore) {
            VStack(alignment: .leading, spacing: 8) {
                Text("About the show")
                    .font(.headline)
                    .foregroundStyle(AppColor.Text.primary)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Text("Read more")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.Accent.strong)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.Surface.muted, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Shows the full description")
    }
}
