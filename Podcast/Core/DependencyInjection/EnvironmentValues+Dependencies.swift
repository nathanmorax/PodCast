//
//  EnvironmentValues+Dependencies.swift
//  Podcast
//

import SwiftUI

/// App-wide dependencies for SwiftUI views.
///
/// Why `@Entry` with a `.shared` default instead of `.environment(object)`:
/// most of our SwiftUI views live inside UIKit cells (`UIHostingConfiguration`).
/// The SwiftUI environment does NOT flow from `RootView` through UIKit into those
/// cells, so a type-based `@Environment(DownloadManager.self)` would crash there.
/// A default that resolves to the singleton works everywhere, and previews/tests
/// override it with `.environment(\.downloadManager, .preview)`.
///
/// The defaults are stable: `.shared` is always the same instance (see the
/// SwiftUI guidance on unstable `@Entry` defaults).
extension EnvironmentValues {
    /// `EnvironmentKey.defaultValue` is nonisolated, but the managers are `@MainActor`.
    /// SwiftUI always reads the environment on the main thread, so `assumeIsolated`
    /// is safe here (and traps loudly if that assumption is ever broken).
    @Entry var playerManager: PlayerManager = MainActor.assumeIsolated { PlayerManager.shared }
    @Entry var downloadManager: DownloadManager = MainActor.assumeIsolated { DownloadManager.shared }
    @Entry var recentlyPlayed: RecentlyPlayedManager = MainActor.assumeIsolated { RecentlyPlayedManager.shared }
    @Entry var recentSearches: RecentSearchesManager = MainActor.assumeIsolated { RecentSearchesManager.shared }
}
