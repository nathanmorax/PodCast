//
//  ZoomBackTransition.swift
//  Podcast
//

import UIKit

/// A page shrinking back into the item it came from: a snapshot of the page,
/// clipped, moves and scales until its cover sits exactly on the item's
/// cover, rounds its corners like it, and fades out to reveal the real one.
@MainActor
enum ZoomBackTransition {

    /// - Parameters:
    ///   - snapshot: the page, as it was when let go.
    ///   - pageFrame: where the page was, in `container` coordinates.
    ///   - cover: the page's cover, in `container` coordinates.
    ///   - target: the item's cover, in `container` coordinates.
    static func run(
        snapshot: UIView,
        pageFrame: CGRect,
        cover: CGRect,
        into target: CGRect,
        cornerRadius: CGFloat,
        in container: UIView
    ) {
        let clip = UIView(frame: pageFrame)
        clip.clipsToBounds = true
        clip.layer.cornerCurve = .continuous
        snapshot.frame = clip.bounds
        clip.addSubview(snapshot)
        container.addSubview(clip)

        // The page's cover, relative to the page.
        let coverInPage = cover.offsetBy(dx: -pageFrame.minX, dy: -pageFrame.minY)
        let scale = target.width / max(coverInPage.width, 1)
        // Scale around the snapshot's center, then put the page's cover
        // center on the clip's (which ends up the size of the target).
        let finalCenter = CGPoint(
            x: (snapshot.bounds.midX - coverInPage.midX) * scale + target.width / 2,
            y: (snapshot.bounds.midY - coverInPage.midY) * scale + target.height / 2
        )

        UIView.animate(AppAnimation.zoomBack) {
            clip.frame = target
            clip.layer.cornerRadius = cornerRadius
            snapshot.transform = CGAffineTransform(scaleX: scale, y: scale)
            snapshot.center = finalCenter
        } completion: {
            clip.removeFromSuperview()
        }
        // The last stretch: the real cover is already underneath.
        UIView.animate(withDuration: 0.16, delay: 0.26, options: [.curveEaseIn]) {
            clip.alpha = 0
        }
    }

    /// No item to go back to (it scrolled away, or the page was opened from
    /// a menu): the page drops down off the screen, like Search.
    static func slideDown(snapshot: UIView, pageFrame: CGRect, in container: UIView) {
        snapshot.frame = pageFrame
        container.addSubview(snapshot)
        UIView.animate(AppAnimation.screenSlide) {
            snapshot.frame.origin.y = container.bounds.height
        } completion: {
            snapshot.removeFromSuperview()
        }
    }
}
