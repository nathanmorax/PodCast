//
//  UIView+AppAnimation.swift
//  Podcast
//

import SwiftUI
import UIKit

/// UIKit animations with the app's SwiftUI curves (iOS 18+ API).
///
/// `UIView.animate(_:changes:completion:)` takes a SwiftUI `Animation`, so the
/// UIKit navigation stacks and the SwiftUI bar share AppAnimation's springs.
/// Like in SwiftUI, an animation interrupted by a new one keeps its velocity
/// instead of jumping, which is what interactive gestures need.
extension UIView {

    /// `UIView.animate(AppAnimation.screenSlide) { … }`
    static func animate(
        _ animation: Animation,
        _ changes: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        animate(animation, changes: changes, completion: completion)
    }
}
