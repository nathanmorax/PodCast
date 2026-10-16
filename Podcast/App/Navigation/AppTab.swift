//
//  AppTab.swift
//  Podcast
//

import Foundation

/// The two tabs of the bottom bar, in order (left to right). Search is not a
/// tab: it has its own stack, opened from the bar's search field.
enum AppTab: Int, CaseIterable, Identifiable {
    case home
    case library

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home:    String(localized: "Home")
        case .library: String(localized: "Library")
        }
    }

    var systemImage: String {
        switch self {
        case .home:    "house"
        case .library: "square.stack"
        }
    }

    var selectedSystemImage: String { systemImage + ".fill" }

    /// The tab to the right (`towardNext`) or to the left, or nil at the ends.
    func neighbor(towardNext next: Bool) -> AppTab? {
        AppTab(rawValue: rawValue + (next ? 1 : -1))
    }
}
