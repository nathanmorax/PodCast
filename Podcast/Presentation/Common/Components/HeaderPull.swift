//
//  HeaderPull.swift
//  Podcast
//

import CoreGraphics
import Observation

/// How far the list is pulled down past the top. The controller writes it
/// from the scroll position (it only changes while pulling); the header's
/// cover reads it and moves up by the same amount, so it stays pinned to the
/// top of the screen. No zoom: its size never changes.
@MainActor
@Observable
final class HeaderPull {
    var distance: CGFloat = 0
}
