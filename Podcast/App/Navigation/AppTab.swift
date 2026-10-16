//
//  AppTab.swift
//  Podcast
//

import Foundation

/// The two tabs of the bottom bar. Search is not a tab: it's pushed on top of
/// whichever tab you're in.
enum AppTab: Int, CaseIterable, Identifiable {
    case home
    case library

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home:    "Inicio"
        case .library: "Biblioteca"
        }
    }

    var systemImage: String {
        switch self {
        case .home:    "house"
        case .library: "square.stack"
        }
    }

    var selectedSystemImage: String { systemImage + ".fill" }
}
