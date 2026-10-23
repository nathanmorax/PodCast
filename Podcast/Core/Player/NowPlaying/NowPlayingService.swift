//
//  NowPlayingService.swift
//  Podcast
//

import Foundation

/// The bridge to the system's Now Playing (MediaPlayer). PlayerManager only
/// talks to this protocol, so tests use a fake and never touch the real
/// lock screen.
@MainActor
protocol NowPlayingService: AnyObject {
    /// Called for each control pressed outside the app. Return false when it
    /// couldn't be done (nothing loaded), so the system knows.
    var onCommand: ((RemoteCommand) -> Bool)? { get set }

    /// Shows (or refreshes) the episode outside the app.
    func update(_ state: NowPlayingState)

    /// Nothing is playing: removes it from the lock screen.
    func clear()
}
