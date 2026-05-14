//
//  PerformanceCategories.swift
//  Podcast
//

import Foundation

enum PerformanceCategory: String {
    case scroll
    case rendering
    case networking
    case persistence
    case audio
    
    /// Bundle identifier de la app, usado como subsystem en os_signpost.
    /// Se lee dinámicamente para que siempre coincida con la configuración del target.
    var subsystem: String {
        Bundle.main.bundleIdentifier ?? "nathan.mora.Podcast"
    }
}
