//
//  LibrarySectionHeader.swift
//  Podcast
//

import SwiftUI

/// A section's title in serif and, on the right, "Show all" when the section
/// has more than its row shows.
struct LibrarySectionHeader: View {

    let title: LocalizedStringKey
    var onShowAll: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppFont.sectionTitle)
                .foregroundStyle(AppColor.Text.primary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let onShowAll {
                Button("Show all", action: onShowAll)
                    .font(AppFont.label)
                    .foregroundStyle(AppColor.Text.secondary)
            }
        }
        .padding(.horizontal, 20)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    LibrarySectionHeader(title: "Browse podcasts") {}
        .padding(.vertical)
}
