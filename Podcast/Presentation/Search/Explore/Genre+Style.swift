//
//  Genre+Style.swift
//  Podcast
//

import SwiftUI

/// How a category looks on its card in Search: an SF Symbol drawn like a
/// line illustration, and a pastel that stays the same wherever it shows.
extension Genre {

    /// The symbol for this category (a waveform for any we don't know).
    var symbolName: String {
        switch id {
        case "1303": "theatermasks"
        case "1489": "newspaper"
        case "1488": "magnifyingglass"
        case "1324": "person.2"
        case "1321": "chart.line.uptrend.xyaxis"
        case "1512": "figure.run"
        case "1545": "sportscourt"
        case "1487": "building.columns"
        case "1533": "atom"
        case "1318": "cpu"
        case "1304": "graduationcap"
        case "1301": "paintpalette"
        case "1309": "film"
        case "1310": "music.note"
        case "1483": "book"
        case "1305": "figure.2.and.child.holdinghands"
        default: "waveform"
        }
    }

    /// Its pastel, by its place in the catalog, so a category keeps its
    /// color however the list is ordered.
    var cardColor: Color {
        let palette = AppColor.Category.palette
        let index = Genre.podcastCatalog.firstIndex { $0.id == id }
            ?? id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[index % palette.count]
    }
}
