//
//  AppTab.swift
//  Podcast
//

import Foundation

/// The app's main screen, shown as "Library" (Following and Favorites live
/// inside it). Search is not a tab: it has its own stack, opened from the
/// bar's search field. Kept as an enum so the container can grow tabs again.
enum AppTab: Int, CaseIterable, Identifiable {
    case home

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: String(localized: "Library")
        }
    }

    var systemImage: String {
        switch self {
        case .home: "square.stack"
        }
    }
}
