//
//  PlayerDismissRule.swift
//  Podcast
//

import CoreGraphics

/// When letting go of the full player closes it. Pure, so it's unit tested.
enum PlayerDismissRule {
    /// Pulled at least this far down…
    static let distance: CGFloat = 140
    /// …or flicked: where the drag would end with its current speed.
    static let flick: CGFloat = 420

    static func shouldClose(translation: CGFloat, predictedEnd: CGFloat) -> Bool {
        guard translation > 0 else { return false }
        return translation > distance || predictedEnd > flick
    }
}
