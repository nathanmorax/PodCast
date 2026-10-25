//
//  LibrarySectionHeader.swift
//  Podcast
//

import SwiftUI

/// A section's title in serif and, on the right, "Show all" when the section
/// has more than its row shows.
struct LibrarySectionHeader: View {

    let title: LocalizedStringKey
    /// A short line under the title, saying what the section is.
    var subtitle: LocalizedStringKey? = nil
    var onShowAll: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.sectionTitle)
                    .foregroundStyle(AppColor.Text.primary)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.footnote)
                        .foregroundStyle(AppColor.Text.secondary)
                }
            }
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
