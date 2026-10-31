//
//  SearchSectionHeader.swift
//  Podcast
//

import SwiftUI

/// A section's name in bold ("Recent", "Episodes"…), like Home's, with an
/// optional link in the accent on the right ("Clear").
struct SearchSectionHeader: View {

    let title: LocalizedStringKey
    var actionTitle: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColor.Text.primary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.Accent.strong)
                    .frame(minHeight: 44)
            }
        }
    }
}
