//
//  EpisodesController+Zoom.swift
//  Podcast
//

import UIKit

/// Opening and closing a podcast's page like Apple Podcasts: the system's
/// zoom transition (iOS 18, `preferredTransition = .zoom`). It grows the
/// page out of the cover that was tapped and, closing, shrinks it back into
/// that cover: with the back button, swiping from the edge, or dragging the
/// page down. The gesture is continuous: it follows the finger, and can be
/// reversed halfway.
extension EpisodesController {

    /// Every place that opens a podcast uses this.
    static func make(for podcast: Podcast) -> EpisodesController {
        let page = EpisodesController()
        page.podcast = podcast
        page.preferredTransition = .zoom(options: zoomOptions(for: page)) { _ in
            // Looked up by id every time (opening and closing), never a
            // captured view: rows get reused, and the list may have moved.
            // nil (the cover scrolled away): the system uses its default.
            ZoomSources.shared.anchor(for: podcast.id)
        }
        return page
    }

    private static func zoomOptions(for page: EpisodesController) -> UIViewController.Transition.ZoomOptions {
        let options = UIViewController.Transition.ZoomOptions()

        // Drag down closes only from the top of the page: further down, the
        // same drag scrolls the episodes. No alignment rect: like Apple
        // Podcasts, the whole page shrinks into the cover.
        options.interactiveDismissShouldBegin = { [weak page] context in
            guard let page else { return context.willBegin }
            return context.willBegin && page.isScrolledToTop
        }

        return options
    }
}
