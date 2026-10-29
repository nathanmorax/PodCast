//
//  LibraryShowHeader.swift
//  Podcast
//

import SwiftUI

/// The band over each show in the Library: the show's own color (read
/// from its cover), the small cover, its name in tall white capitals and
/// a mustard tag ("3 NEW").
struct LibraryShowHeader: View {

    let name: String
    let artwork: String?
    let badge: Text

    /// The cover's color; read once it loads (cached after that).
    @State private var loadedTint: ArtworkTint?

    private var tint: ArtworkTint? {
        loadedTint ?? ArtworkTintLoader.cachedTint(for: artwork)
    }

    var body: some View {
        HStack(spacing: 12) {
            PodcastImage(source: artwork)
                .frame(width: 40, height: 40)
                .clipped()
                .accessibilityHidden(true)

            Text(name)
                .font(.system(.title3, weight: .bold).width(.compressed))
                .textCase(.uppercase)
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            badge
                .font(.caption2.weight(.heavy))
                .textCase(.uppercase)
                .tracking(0.8)
                .foregroundStyle(AppColor.Text.onPastel)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(AppColor.Accent.soft)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background {
            // A light scrim keeps the white name readable on pale covers.
            ZStack {
                tint?.color ?? Color(white: 0.22)
                Color.black.opacity(0.18)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .task(id: artwork) {
            guard loadedTint == nil else { return }
            let tint = await ArtworkTintLoader.tint(for: artwork)
            withAnimation(AppAnimation.stateChange) { loadedTint = tint }
        }
    }
}
