//
//  RemoteCommand.swift
//  Podcast
//

import Foundation

/// A control pressed outside the app: lock screen, Control Center, AirPods
/// (press, double and triple press), headphones' buttons, a car's controls.
enum RemoteCommand: Equatable, Sendable {
    case play
    case pause
    case togglePlayPause
    /// ⟳ 15 on the lock screen; also AirPods' double press ("next track").
    case skipForward
    /// ⟲ 15 on the lock screen; also AirPods' triple press ("previous track").
    case skipBackward
    /// Dragging the lock screen's progress bar.
    case seek(toSeconds: Double)
}
