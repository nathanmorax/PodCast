//
//  GenreTile.swift
//  Podcast
//

import SwiftUI

/// A category in Search, editorial (like a magazine's "Sections"): a soft
/// pastel tile with a line drawing in the middle and the name under it,
/// in black.
struct GenreTile: View {

    let genre: Genre

    static let height: CGFloat = 132

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: genre.symbolName)
                .font(.system(size: 34, weight: .light))
                .symbolRenderingMode(.monochrome)
            Text(genre.name)
                .font(.system(.callout, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.08))
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: Self.height)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(genre.pastel))
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(genre.name)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Each category's drawing and color

extension Genre {

    /// A line drawing (SF Symbol) that says the category.
    var symbolName: String {
        switch id {
        case "1303": "theatermasks"
        case "1489": "globe.americas"
        case "1488": "magnifyingglass"
        case "1324": "person.2"
        case "1321": "chart.line.uptrend.xyaxis"
        case "1512": "leaf"
        case "1545": "figure.run"
        case "1487": "building.columns"
        case "1533": "atom"
        case "1318": "cpu"
        case "1304": "graduationcap"
        case "1301": "paintpalette"
        case "1309": "film"
        case "1310": "music.note"
        case "1483": "book.closed"
        case "1305": "figure.and.child.holdinghands"
        default: "mic"
        }
    }

    /// Soft pastels that take turns; black text and drawing read on all.
    var pastel: Color {
        let palette: [Color] = [
            Color(red: 0.89, green: 0.94, blue: 0.98),   // sky
            Color(red: 0.97, green: 0.87, blue: 0.80),   // peach
            Color(red: 0.95, green: 0.95, blue: 0.93),   // paper
            Color(red: 0.87, green: 0.93, blue: 0.92),   // mint
            Color(red: 0.98, green: 0.91, blue: 0.93),   // rose
            Color(red: 0.91, green: 0.91, blue: 0.97),   // lavender
            Color(red: 0.98, green: 0.93, blue: 0.75),   // butter
            Color(red: 0.95, green: 0.93, blue: 0.87),   // sand
        ]
        let index = Genre.podcastCatalog.firstIndex(of: self) ?? abs(id.hashValue)
        return palette[index % palette.count]
    }
}
