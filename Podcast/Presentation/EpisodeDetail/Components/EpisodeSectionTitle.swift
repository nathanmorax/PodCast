//
//  EpisodeSectionTitle.swift
//  Podcast
//

import SwiftUI

/// "WHY LISTEN", "CHAPTERS"…: the episode page's section names, small heavy
/// capitals like a film page's.
struct EpisodeSectionTitle: View {

    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.caption.weight(.heavy))
            .textCase(.uppercase)
            .tracking(1)
            .accessibilityAddTraits(.isHeader)
    }
}
