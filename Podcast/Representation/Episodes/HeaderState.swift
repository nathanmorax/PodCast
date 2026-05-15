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
    case bookmark
    case download
}

// MARK: - EpisodeHeaderActions

final class EpisodeHeaderActions {

    let events: AsyncStream<EpisodeHeaderEvent>
    private let continuation: AsyncStream<EpisodeHeaderEvent>.Continuation

    init() {
        // makeStream garantiza que continuation existe antes de cualquier send()
        (events, continuation) = AsyncStream.makeStream(of: EpisodeHeaderEvent.self)
    }

    func send(_ event: EpisodeHeaderEvent) {
        continuation.yield(event)
    }

    deinit {
        // Finaliza el stream para que el for await en el controller termine limpiamente
        continuation.finish()
    }
}
