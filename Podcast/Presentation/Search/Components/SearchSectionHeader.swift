//
//  SearchSectionHeader.swift
//  Podcast
//

import SwiftUI

/// A small spaced-out overline ("RECENT", "EPISODES"…) with an optional
/// link on the right ("Clear").
struct SearchSectionHeader: View {

    let title: LocalizedStringKey
    var actionTitle: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .overlineStyle()
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(AppFont.captionStrong)
                    .foregroundStyle(AppColor.Accent.strong)
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    SearchSectionHeader(title: "Recent", actionTitle: "Clear") {}
        .padding()
}
