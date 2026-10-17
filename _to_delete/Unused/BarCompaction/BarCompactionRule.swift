//
//  BarCompactionRule.swift
//  Podcast
//

import CoreGraphics

/// Decides when the bottom bar folds, from the scroll offset alone (no UIKit),
/// so it can be unit tested. Used by BottomBarScrollTracker.
///
/// - Scrolling down more than `distance` folds it.
/// - Scrolling back up more than `distance` unfolds it.
/// - Within `top` points of the top it's always unfolded.
/// - Offsets that don't come from the user's finger (inset changes,
///   programmatic jumps) never change it.
struct BarCompactionRule {

    var distance: CGFloat = 36
    var top: CGFloat = 24

    /// Furthest point reached in the current direction.
    private(set) var anchor: CGFloat = 0

    mutating func reset(at offset: CGFloat) {
        anchor = offset
    }

    /// The bar's state after scrolling to `offset`.
    mutating func update(offset y: CGFloat, isUserScrolling: Bool, isCompact: Bool) -> Bool {
        guard isUserScrolling else {
            anchor = y
            return isCompact
        }
        if y <= top {
            anchor = y
            return false
        }
        if isCompact {
            if y > anchor {
                anchor = y
            } else if anchor - y > distance {
                anchor = y
                return false
            }
        } else {
            if y < anchor {
                anchor = y
            } else if y - anchor > distance {
                anchor = y
                return true
            }
        }
        return isCompact
    }
}
