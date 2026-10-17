//
//  BottomBarScrollTracker.swift
//  Podcast
//

import UIKit

/// Watches the visible screen's main scroll view and folds the bottom bar
/// while you scroll down, unfolding it when you scroll back up or reach the top.
///
/// Works for UIKit lists and SwiftUI ScrollViews alike, because both end up
/// as a UIScrollView in the hierarchy.
@MainActor
final class BottomBarScrollTracker {

    private let navigator: AppNavigator
    private var observation: NSKeyValueObservation?
    private var attachTask: Task<Void, Never>?
    private var rule = BarCompactionRule()

    init(navigator: AppNavigator) {
        self.navigator = navigator
    }

    /// Starts following the main scroll view of `viewController`.
    func track(_ viewController: UIViewController) {
        attachTask?.cancel()
        observation = nil
        navigator.isBarCompact = false

        attachTask = Task { @MainActor [weak self, weak viewController] in
            // SwiftUI screens create their UIScrollView after the first layout
            // pass, so look a few times before giving up.
            for _ in 0..<5 {
                try? await Task.sleep(for: .milliseconds(120))
                guard !Task.isCancelled, let self, let viewController else { return }
                if let scrollView = Self.mainScrollView(in: viewController) {
                    self.attach(to: scrollView)
                    return
                }
            }
        }
    }

    private func attach(to scrollView: UIScrollView) {
        rule.reset(at: Self.offset(of: scrollView))
        observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
            MainActor.assumeIsolated {
                self?.handle(scrollView)
            }
        }
    }

    private func handle(_ scrollView: UIScrollView) {
        // Only the user's own scrolling counts: inset changes or programmatic
        // jumps must not fold the bar.
        let compact = rule.update(
            offset: Self.offset(of: scrollView),
            isUserScrolling: scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating,
            isCompact: navigator.isBarCompact
        )
        if compact != navigator.isBarCompact {
            navigator.isBarCompact = compact
        }
    }

    /// Offset from the top of the content, clamped so the bounce at either
    /// end doesn't count as a change of direction.
    private static func offset(of scrollView: UIScrollView) -> CGFloat {
        let insets = scrollView.adjustedContentInset
        let y = scrollView.contentOffset.y + insets.top
        let maxY = max(0, scrollView.contentSize.height + insets.top + insets.bottom - scrollView.bounds.height)
        return min(max(y, 0), maxY)
    }

    /// The scroll view the screen declared, or the first big visible one.
    private static func mainScrollView(in viewController: UIViewController) -> UIScrollView? {
        if let declared = viewController.contentScrollView(for: .bottom)
            ?? viewController.contentScrollView(for: .top) {
            return declared
        }

        let minimumHeight = viewController.view.bounds.height * 0.5
        var queue: [UIView] = [viewController.view]
        while !queue.isEmpty {
            let view = queue.removeFirst()
            if let scrollView = view as? UIScrollView,
               !(scrollView is UITextView),
               scrollView.bounds.height >= minimumHeight {
                return scrollView
            }
            queue.append(contentsOf: view.subviews.filter { !$0.isHidden && $0.alpha > 0 })
        }
        return nil
    }
}
