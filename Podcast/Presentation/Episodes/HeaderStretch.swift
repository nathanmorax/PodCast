//
//  HeaderStretch.swift
//  Podcast
//

import CoreGraphics
import Observation

/// How far the list is pulled down past the top. The controller writes it
/// from scrollViewDidScroll (only while pulling); the header's cover reads it
/// and grows upward to fill the gap. Nothing else re-renders.
@MainActor
@Observable
final class HeaderStretch {
    var pull: CGFloat = 0
}
