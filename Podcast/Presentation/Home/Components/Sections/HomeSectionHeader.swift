//
//  HomeSectionHeader.swift
//  Podcast
//

import SwiftUI

/// "Your Podcasts" in bold, with "See All" in the accent on the right.
struct HomeSectionHeader: View {

    let title: LocalizedStringKey
    var onSeeAll: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppColor.Text.primary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 12)
            if let onSeeAll {
                Button("See All", action: onSeeAll)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppColor.Accent.strong)
                    .frame(minHeight: 44)
            }
        }
    }
}
