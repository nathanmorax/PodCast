//
//  GenrePodcastCell.swift
//  Podcast
//
//  Created by Jesus Mora on 25/02/26.
//
import SwiftUI

/// A category card: its color, its name, and the covers of its top two
/// podcasts tilted in the corner.
struct GenrePodcastCell: View {
    let genre: Genre
    let index: Int
    /// Artwork of the category's top two podcasts. Empty until that comes from
    /// the API: frosted placeholders show instead.
    var coverURLs: [String] = []

    var body: some View {
        Text(genre.name)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(AppColor.ink)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .padding(.trailing, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(14)
            .frame(height: 128)
            .background(Self.color(for: index))
            .overlay(alignment: .bottomTrailing) { covers }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(genre.name)
            .accessibilityAddTraits(.isButton)
    }

    private var covers: some View {
        ZStack(alignment: .bottomTrailing) {
            cover(at: 1)
                .rotationEffect(.degrees(-9))
                .offset(x: -36, y: 6)
            cover(at: 0)
                .rotationEffect(.degrees(7))
                .offset(y: -10)
        }
        .padding(.trailing, 8)
    }

    private func cover(at position: Int) -> some View {
        let url = coverURLs.indices.contains(position) ? coverURLs[position] : nil
        return PodcastImage(source: url, placeholder: .white.opacity(position == 0 ? 0.75 : 0.5))
            .frame(width: 62, height: 62)
            .overlay {
                if url == nil {
                    Image(systemName: "waveform")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.22))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 7, x: 0, y: 6)
    }

    /// Cycles the palette without repeating the previous card's color.
    static func color(for index: Int) -> Color {
        let palette = AppColor.palette
        var newIndex = index % palette.count
        if index > 0 && newIndex == (index - 1) % palette.count {
            newIndex = (newIndex + 1) % palette.count
        }
        return palette[newIndex]
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    GenrePodcastCell(genre: .mock, index: 0)
        .frame(width: 180)
        .padding()
}
