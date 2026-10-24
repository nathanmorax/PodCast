//
//  ZoomSources.swift
//  Podcast
//

import SwiftUI
import UIKit

/// The podcast covers on screen, so a podcast's page can close back into
/// the item it was opened from (like Apple Podcasts).
///
/// The system zoom transition (EpisodesController.make) needs a UIView to
/// zoom from and back into. SwiftUI images inside hosting controllers have
/// none, so the covers that open a podcast are drawn by UIKit
/// (ZoomSourceImage) and register here. Being the real cover matters: the
/// system hides the source while the page travels and shows it again once
/// the page lands on it. An invisible view behind a SwiftUI image left the
/// image on screen the whole time, and the landing looked like a jump.
///
/// No gesture is added to the cover: a gesture inside a Button's label
/// takes the tap away from the Button, and the item stops opening.
@MainActor
final class ZoomSources {

    static let shared = ZoomSources()

    private struct Entry {
        weak var view: UIView?
        var podcastID: Int
        var cornerRadius: CGFloat
    }

    private var entries: [ObjectIdentifier: Entry] = [:]

    func register(_ view: UIView, podcastID: Int, cornerRadius: CGFloat) {
        entries = entries.filter { $0.value.view != nil }
        // The zoom takes the source's shape: a circle, rounded corners…
        view.layer.cornerRadius = cornerRadius
        view.layer.cornerCurve = .continuous
        entries[ObjectIdentifier(view)] = Entry(view: view, podcastID: podcastID, cornerRadius: cornerRadius)
    }

    /// The podcast's cover: the zoom transition grows the page out of it
    /// and shrinks it back into it. The one on screen (the biggest, if it
    /// shows up in more than one place).
    func anchor(for podcastID: Int) -> UIView? {
        let alive = entries.values.compactMap { entry -> UIView? in
            guard entry.podcastID == podcastID,
                  let view = entry.view,
                  !view.bounds.isEmpty else { return nil }
            return view
        }
        let onScreen = alive.filter { $0.window != nil }
        return (onScreen.isEmpty ? alive : onScreen).max { $0.bounds.width < $1.bounds.width }
    }
}
