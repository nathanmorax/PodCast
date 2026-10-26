//
//  EpisodeHeaderActions.swift
//  Podcast
//

import SwiftUI

// MARK: - EpisodeHeaderEvent

enum EpisodeHeaderEvent {
    case play
    /// The + / ✓ in the header: follow or unfollow the podcast.
    case follow
    /// The ⓘ next to the description: the full "About" in a sheet.
    case about
}

// MARK: - EpisodeHeaderActions

/// Sendable: its only state is an AsyncStream and its continuation, both
/// Sendable and immutable, so the environment's shared default is safe.
final class EpisodeHeaderActions: Sendable {

    let events: AsyncStream<EpisodeHeaderEvent>
    private let continuation: AsyncStream<EpisodeHeaderEvent>.Continuation

    init() {
        (events, continuation) = AsyncStream.makeStream(of: EpisodeHeaderEvent.self)
    }

    func send(_ event: EpisodeHeaderEvent) {
        continuation.yield(event)
    }

    deinit {
        continuation.finish()
    }
}

// MARK: - Environment

private struct EpisodeHeaderActionsKey: EnvironmentKey {
    static let defaultValue = EpisodeHeaderActions()
}

extension EnvironmentValues {
    var episodeActions: EpisodeHeaderActions {
        get { self[EpisodeHeaderActionsKey.self] }
        set { self[EpisodeHeaderActionsKey.self] = newValue }
    }
}
