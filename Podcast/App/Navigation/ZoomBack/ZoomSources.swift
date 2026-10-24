//
//  ZoomSources.swift
//  Podcast
//

import SwiftUI
import UIKit

/// The podcast covers on screen, so a podcast's page can close back into
/// the item it was opened from (like Apple Podcasts).
///
/// Each cover carries an invisible UIView behind it (`.zoomSource`): the
/// system zoom transition (EpisodesController.make) needs a UIView to zoom
/// from and back into, and SwiftUI covers inside hosting controllers have
/// none of their own.
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

// MARK: - Anchor view

/// An invisible UIView placed exactly where a SwiftUI view is, so UIKit can
/// ask where that is. Doesn't take touches.
struct ViewAnchor: UIViewRepresentable {

    let onAttach: (UIView) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        onAttach(view)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        // Rows are reused for other podcasts: register again with the new one.
        onAttach(view)
    }
}

extension View {
    /// This view is the podcast's cover: its page closes back into it.
    func zoomSource(for podcast: Podcast, cornerRadius: CGFloat) -> some View {
        let id = podcast.id
        return background {
            ViewAnchor { view in
                ZoomSources.shared.register(view, podcastID: id, cornerRadius: cornerRadius)
            }
        }
    }
}
