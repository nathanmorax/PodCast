//
//  GenreCard.swift
//  Podcast
//

import SwiftUI

/// A category in "Explore", like a magazine's section cards: a pastel card
/// with the category's symbol drawn thin, and its name under it, both in
/// ink. Two per row (GenreGrid in SearchExploreView).
struct GenreCard: View {

    let genre: Genre

    static let height: CGFloat = 150

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: genre.symbolName)
                .font(.system(size: 38, weight: .light))
                .symbolRenderingMode(.monochrome)
                .frame(height: 44)
                .accessibilityHidden(true)

            Text(genre.name)
                .font(.body)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(AppColor.Text.onPastel)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: Self.height)
        .background(
            genre.cardColor,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(genre.name)
        .accessibilityAddTraits(.isButton)
    }
}
