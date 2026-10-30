//
//  LibraryLayout.swift
//  Podcast
//

import Foundation

/// How the Library lays out each show's episodes: lines, or a grid of
/// covers two or three across. The listener picks it at the top of the
/// Library; it's remembered between visits (AppStorage, by raw value).
enum LibraryLayout: String, CaseIterable, Identifiable {
    case list
    case twoColumns
    case threeColumns

    var id: Self { self }

    /// How many covers across; nil for the list.
    var columns: Int? {
        switch self {
        case .list: nil
        case .twoColumns: 2
        case .threeColumns: 3
        }
    }

    /// For VoiceOver (the picker only shows the symbol).
    var title: LocalizedStringResource {
        switch self {
        case .list: "List"
        case .twoColumns: "Two columns"
        case .threeColumns: "Three columns"
        }
    }

    var systemImage: String {
        switch self {
        case .list: "list.bullet"
        case .twoColumns: "square.grid.2x2"
        case .threeColumns: "square.grid.3x3"
        }
    }
}
