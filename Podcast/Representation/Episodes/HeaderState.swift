//
//  HeaderState.swift
//  Podcast
//
//  Created by Satori Tech 341 on 12/05/26.
//
import SwiftUI

struct HeaderState: Equatable {
    
    let isFavorite: Bool
    let description: String?
    let isLoadingDescription: Bool
}

enum EpisodeHeaderEvent {
    case play
    case bookmark
    case download
}

struct EpisodeHeaderActions {
    
    private var continuation: AsyncStream<EpisodeHeaderEvent>.Continuation?
    
    lazy var events: AsyncStream<EpisodeHeaderEvent> = {
        AsyncStream { self.continuation = $0 }
    }()
    
    func send(_ event: EpisodeHeaderEvent) {
        continuation?.yield(event)
    }
}
