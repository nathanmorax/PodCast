//
//  Logger+App.swift
//  Podcast
//

import OSLog

extension Logger {

    private static let subsystem = Bundle.main.bundleIdentifier ?? "Podcast"

    /// Network requests: what was asked, how long it took, what came back.
    /// See them in Xcode's console or Console.app (filter by the category
    /// "Network"); a request's query (what you searched) is private.
    static let network = Logger(subsystem: subsystem, category: "Network")
}

extension URL {
    /// "itunes.apple.com/search" (host and path; no query) for the logs.
    var logDescription: String {
        (host() ?? "") + path()
    }
}
