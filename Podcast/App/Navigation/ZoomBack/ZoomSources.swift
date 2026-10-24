//
//  ZoomSources.swift
//  Podcast
//

import UIKit

/// The items on screen that a screen can zoom out of and back into.
///
/// The system zoom transition (`pushZooming(_:from:)`) needs a UIView to
/// zoom from. SwiftUI content inside hosting controllers has none, so the
/// items are drawn by UIKit (ZoomSourceImage for a cover, ZoomSourceHost for
/// anything else) and register here under a ZoomID. Being the real item
/// matters: the system hides it while the screen travels and shows it again
/// once the screen lands on it. An invisible view behind a SwiftUI image
/// left the image on screen the whole time, and the landing looked like a
/// jump.
///
/// No gesture is added to the item: a gesture inside a Button's label takes
/// the tap away from the Button, and the item stops opening.
@MainActor
final class ZoomSources {

    static let shared = ZoomSources()

    private struct Entry {
        weak var view: UIView?
        var id: ZoomID
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    func register(_ view: UIView, id: ZoomID, cornerRadius: CGFloat) {
        entries = entries.filter { $0.value.view != nil }
        // The zoom takes the source's shape: a circle, rounded corners…
        view.layer.cornerRadius = cornerRadius
        view.layer.cornerCurve = .continuous
        entries[ObjectIdentifier(view)] = Entry(view: view, id: id)
    }

    /// The item's view: the one on screen, the biggest if the item shows up
    /// in more than one place. nil (scrolled away): the system zooms from
    /// the middle of the screen instead.
    func anchor(for id: ZoomID) -> UIView? {
        let alive = entries.values.compactMap { entry -> UIView? in
            guard entry.id == id, let view = entry.view, !view.bounds.isEmpty else { return nil }
            return view
        }
        let onScreen = alive.filter { $0.window != nil }
        return (onScreen.isEmpty ? alive : onScreen).max { $0.bounds.width < $1.bounds.width }
    }
}
