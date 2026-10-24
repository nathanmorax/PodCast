//
//  UIViewController+ZoomPush.swift
//  Podcast
//

import UIKit

/// A screen that can tell whether dragging down should close it. Screens
/// with a scrolling page adopt it: only from the top, so further down the
/// same drag scrolls.
@MainActor
protocol ZoomDismissible: AnyObject {
    var isScrolledToTop: Bool { get }
}

extension UIViewController {

    /// Pushes `screen` growing out of the item `id` (the system's zoom
    /// transition, iOS 18, like Apple Podcasts). Closing it (back button,
    /// swipe from the edge, or dragging the page down) shrinks it back into
    /// that same item. The gesture follows the finger and can be reversed
    /// halfway.
    ///
    /// The item must be drawn with ZoomSourceImage or ZoomSourceHost. Don't
    /// open these screens with `setViewControllers`: the drag-down gesture
    /// doesn't work then (Apple Developer Forums 792753).
    func pushZooming(_ screen: UIViewController, from id: ZoomID) {
        let options = UIViewController.Transition.ZoomOptions()
        // The interaction context only has the touch (willBegin, location,
        // velocity), not the screen: keep a weak reference to it instead.
        // UIKit calls these closures on the main thread, but doesn't mark
        // them @MainActor: assumeIsolated says so to the compiler.
        options.interactiveDismissShouldBegin = { [weak screen] context in
            let willBegin = context.willBegin
            guard willBegin else { return false }
            return MainActor.assumeIsolated {
                (screen as? ZoomDismissible)?.isScrolledToTop ?? true
            }
        }
        // Looked up by id every time (opening and closing), never a
        // captured view: rows get reused, and the list may have moved.
        // (assumeIsolated only returns Sendable values, and a UIView isn't:
        // it's written to a local instead.)
        screen.preferredTransition = .zoom(options: options) { _ in
            var anchor: UIView?
            MainActor.assumeIsolated {
                anchor = ZoomSources.shared.anchor(for: id)
            }
            return anchor
        }
        navigationController?.pushViewController(screen, animated: true)
    }
}
