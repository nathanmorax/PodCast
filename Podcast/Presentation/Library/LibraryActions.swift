//
//  LibraryActions.swift
//  Podcast
//

import SwiftUI

@MainActor
final class LibraryActions {
    private let stream: AsyncStream<LibraryDestination>
    private let continuation: AsyncStream<LibraryDestination>.Continuation

    var events: AsyncStream<LibraryDestination> { stream }

    init() {
        var continuation: AsyncStream<LibraryDestination>.Continuation!
        stream = AsyncStream { continuation = $0 }
        self.continuation = continuation
    }

    func send(_ destination: LibraryDestination) {
        continuation.yield(destination)
    }
}
