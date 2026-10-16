//
//  EpisodeHeaderActions.swift
//  Podcast
//

import SwiftUI

// MARK: - EpisodeHeaderEvent

enum EpisodeHeaderEvent {
    case play
    case bookmark(Episode)
    case download
}

// MARK: - EpisodeHeaderActions

final class EpisodeHeaderActions {

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
