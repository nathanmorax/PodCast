//
//  EpisodeSectionTitle.swift
//  Podcast
//

import SwiftUI

/// "Why listen", "Chapters"…: the episode page's section names, bold,
/// like Home's and the show page's.
struct EpisodeSectionTitle: View {

    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.title3.weight(.bold))
            .foregroundStyle(AppColor.Text.primary)
            .accessibilityAddTraits(.isHeader)
    }
}
