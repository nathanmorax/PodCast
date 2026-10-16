//
//  HeaderState.swift
//  Podcast
//

import Foundation

// MARK: - HeaderState

struct HeaderState: Equatable {
    let isFavorite: Bool
    let description: String?
    let isLoadingDescription: Bool

    static func == (lhs: HeaderState, rhs: HeaderState) -> Bool {
        lhs.isFavorite == rhs.isFavorite &&
        lhs.isLoadingDescription == rhs.isLoadingDescription &&
        (lhs.description ?? "") == (rhs.description ?? "")
    }
}

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

// EnvironmentValues+HeaderActions.swift

import SwiftUI

private struct EpisodeHeaderActionsKey: EnvironmentKey {
    static let defaultValue = EpisodeHeaderActions()
}

extension EnvironmentValues {
    var episodeActions: EpisodeHeaderActions {
        get { self[EpisodeHeaderActionsKey.self] }
        set { self[EpisodeHeaderActionsKey.self] = newValue }
    }
}
