//
//  MainContainerController.swift
//  Podcast
//

import UIKit

/// One navigation stack for the main screen (Library) plus one for Search.
/// Only one is on screen; the others keep their history for when you come
/// back. There is no UITabBar: the bottom of the screen belongs to RootView's
/// BottomBar.
///
/// Search is the *root* of its own stack instead of being pushed on top of a
/// tab, so it has no back arrow. Opening a podcast from the results still
/// pushes (with its back arrow) inside Search's stack.
///
final class MainContainerController: UIViewController, NavigationContainer {

    private let stacks: [AppTab: UINavigationController]
    let searchController = PodcastSearchContainerController()
    let searchStack: UINavigationController
    private weak var current: UINavigationController?

    private var navigator: AppNavigator { .shared }

    init() {
        var stacks: [AppTab: UINavigationController] = [:]
        for tab in AppTab.allCases {
            stacks[tab] = Self.makeStack(root: Self.makeRoot(for: tab))
        }
        self.stacks = stacks
        self.searchStack = Self.makeStack(root: searchController)
        super.init(nibName: nil, bundle: nil)
        stacks.values.forEach { $0.delegate = self }
        searchStack.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeStack(root: UIViewController) -> UINavigationController {
        let navigation = UINavigationController(rootViewController: root)
        // Back arrows and bar buttons in the app's violet.
        navigation.navigationBar.tintColor = ColorName.accentInk.uiColor
        // Standard (inline) titles everywhere: no large titles, so every
        // header sits at the same height.
        navigation.navigationBar.prefersLargeTitles = false
        return navigation
    }

    private static func makeRoot(for tab: AppTab) -> UIViewController {
        switch tab {
        case .home: HomeController()
        }
    }

    func stack(for tab: AppTab) -> UINavigationController? {
        stacks[tab]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addGestureRecognizer(searchPan)
        // Build Search's screen now (off screen), so opening it the first time
        // doesn't create its views, categories and SwiftUI hosting on the spot.
        searchController.loadViewIfNeeded()
        show(navigator.selectedTab)
    }

    func show(_ tab: AppTab) {
        guard let next = stacks[tab] else { return }
        // Leaving Search: it drops back down, revealing the tab under it.
        display(next, transition: current === searchStack ? .slideDown : .none)
    }

    /// Search rises over the tab (the reverse of pulling it down to leave).
    /// No keyboard: the field gets it only when you tap it in the bar.
    func showSearch() {
        display(searchStack, transition: .slideUp)
    }

    /// Search is already on screen: focus its field. Inside a podcast opened
    /// from the results, go back first; the keyboard comes up once Search is
    /// visible again.
    func focusSearch() {
        if searchStack.topViewController === searchController {
            searchController.focusSearchField()
        } else {
            searchController.focusesSearchOnAppear = true
            searchStack.popToRootViewController(animated: true)
        }
    }

    private enum StackTransition {
        case none
        /// The old stack drops away, revealing the new one under it.
        case slideDown
        /// The new stack rises from the bottom over the old one.
        case slideUp
    }

    private func display(_ next: UINavigationController, transition: StackTransition = .none) {
        guard next !== current else { return }
        let previous = current
        let bounds = view.bounds

        switch transition {
        case .none:
            if let previous { remove(previous) }
            embed(next, frame: bounds)
            didBecomeCurrent(next)

        case .slideDown:
            embed(next, frame: bounds)
            if let previous { view.bringSubviewToFront(previous.view) }
            didBecomeCurrent(next)
            animateStacks {
                previous?.view.frame = bounds.offsetBy(dx: 0, dy: bounds.height)
            } completion: {
                self.removeIfHidden(previous)
            }

        case .slideUp:
            embed(next, frame: bounds.offsetBy(dx: 0, dy: bounds.height))
            didBecomeCurrent(next)
            animateStacks {
                next.view.frame = bounds
            } completion: {
                self.removeIfHidden(previous)
            }
        }
    }

    private func animateStacks(_ changes: @escaping () -> Void, completion: @escaping () -> Void) {
        UIView.animate(AppAnimation.screenSlide, changes: changes, completion: completion)
    }

    /// After an animation, the stack that left is taken out (unless it came
    /// back on screen meanwhile).
    private func removeIfHidden(_ stack: UINavigationController?) {
        guard let stack, stack !== current, stack.parent === self else { return }
        remove(stack)
        stack.view.frame = view.bounds
    }

    private func embed(_ child: UINavigationController, frame: CGRect) {
        if child.parent !== self {
            addChild(child)
        }
        child.view.frame = frame
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }

    private func remove(_ child: UINavigationController) {
        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
    }

    private func didBecomeCurrent(_ stack: UINavigationController) {
        current = stack
        updateBottomBarVisibility(showing: stack.topViewController, in: stack)
        setNeedsStatusBarAppearanceUpdate()
    }

    override var childForStatusBarStyle: UIViewController? { current }

    // MARK: - Gestures

    /// The screen's own scroll starts too: stop it, the pull wins.
    private func cancelScrolling(at point: CGPoint) {
        var candidate = view.hitTest(point, with: nil)
        while let v = candidate, v !== view {
            if let scrollView = v as? UIScrollView {
                scrollView.panGestureRecognizer.isEnabled = false
                scrollView.panGestureRecognizer.isEnabled = true
            }
            candidate = v.superview
        }
    }

    // MARK: - Pull Search down to close it

    /// The tab revealed under Search while it's being pulled down.
    private var tabUnderSearch: UINavigationController?

    private lazy var searchPan: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleSearchPan(_:)))
        pan.delegate = self
        return pan
    }()

    @objc private func handleSearchPan(_ pan: UIPanGestureRecognizer) {
        let height = view.bounds.height
        switch pan.state {
        case .began:
            guard let under = stacks[navigator.selectedTab] else { return }
            cancelScrolling(at: pan.location(in: view))
            // The tab you came from waits underneath; Search slides off it.
            embed(under, frame: view.bounds)
            view.bringSubviewToFront(searchStack.view)
            tabUnderSearch = under

        case .changed:
            guard tabUnderSearch != nil else { return }
            let y = max(0, pan.translation(in: view).y)
            applySearchPull(y)

        case .ended, .cancelled, .failed:
            guard let under = tabUnderSearch else { return }
            tabUnderSearch = nil
            let y = pan.translation(in: view).y
            let completes = pan.state == .ended && (y > height * 0.25 || pan.velocity(in: view).y > 800)
            guard completes else {
                UIView.animate(AppAnimation.gestureRelease) {
                    self.applySearchPull(0)
                } completion: {
                    self.resetSearchPull()
                    self.removeIfHidden(under)
                }
                return
            }
            shrinkSearchIntoBar()

        default:
            break
        }
    }

    // MARK: - Search goes back into the bar

    /// How much Search shrinks while pulled (at a full screen of pull).
    private static let pullShrink: CGFloat = 0.22
    private static let pullCornerRadius: CGFloat = 44

    /// While pulling: Search follows the finger, gets smaller and rounder,
    /// already looking like a card on its way back to the bar.
    private func applySearchPull(_ y: CGFloat) {
        let progress = min(1, y / max(1, view.bounds.height))
        let scale = 1 - Self.pullShrink * progress
        let stackView = searchStack.view!
        stackView.transform = CGAffineTransform(translationX: 0, y: y).scaledBy(x: scale, y: scale)
        stackView.layer.cornerRadius = Self.pullCornerRadius * min(1, progress * 3)
        stackView.layer.cornerCurve = .continuous
        stackView.layer.masksToBounds = progress > 0
    }

    private func resetSearchPull() {
        let stackView = searchStack.view!
        stackView.transform = .identity
        stackView.layer.cornerRadius = 0
        stackView.layer.masksToBounds = false
    }

    /// Where Search lives in the bar on a tab: the search circle next to the
    /// mini player, or the full-width field when nothing is playing. Matches
    /// BottomBar (16 pt sides, 8 pt above the home indicator, 62 pt tall).
    private func searchOriginInBar() -> CGRect {
        let bounds = view.bounds
        let size = BottomBar.Metrics.rowHeight
        let bottomInset = view.window?.safeAreaInsets.bottom ?? 0
        let y = bounds.maxY - bottomInset - 8 - size
        if PlayerManager.shared.currentEpisode != nil {
            return CGRect(x: bounds.maxX - 16 - size, y: y, width: size, height: size)
        }
        return CGRect(x: 16, y: y, width: bounds.width - 32, height: size)
    }

    /// Released far enough: Search shrinks into the bar's search button, so
    /// you see where it came from (and where to find it again). A snapshot
    /// does the trip inside a clipping capsule that morphs into the button.
    private func shrinkSearchIntoBar() {
        let stackView = searchStack.view!
        let startFrame = stackView.frame
        let startScale = stackView.transform.a
        let startRadius = stackView.layer.cornerRadius

        guard !UIAccessibility.isReduceMotionEnabled,
              let snapshot = stackView.snapshotView(afterScreenUpdates: false) else {
            // Reduce Motion (or no snapshot): just drop it down, as before.
            UIView.animate(AppAnimation.gestureRelease) {
                stackView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            } completion: {
                self.finishClosingSearch()
            }
            return
        }

        let target = searchOriginInBar()
        let clipper = UIView(frame: startFrame)
        clipper.clipsToBounds = true
        clipper.layer.cornerCurve = .continuous
        clipper.layer.cornerRadius = startRadius
        clipper.backgroundColor = ColorName.screenBackground.uiColor

        snapshot.bounds = CGRect(origin: .zero, size: view.bounds.size)
        snapshot.center = CGPoint(x: startFrame.width / 2, y: startFrame.height / 2)
        snapshot.transform = CGAffineTransform(scaleX: startScale, y: startScale)
        clipper.addSubview(snapshot)

        // State first (it re-adds the tab's view on top), then the capsule
        // above everything for the trip down.
        finishClosingSearch()
        view.addSubview(clipper)

        // The content shrinks evenly (no stretching) until its width fits
        // the button; the capsule around it crops it to the button's shape.
        let endScale = max(target.width / view.bounds.width, target.height / view.bounds.height)
        UIView.animate(AppAnimation.screenSlide) {
            clipper.frame = target
            clipper.layer.cornerRadius = target.height / 2
            snapshot.center = CGPoint(x: target.width / 2, y: target.height / 2)
            snapshot.transform = CGAffineTransform(scaleX: endScale, y: endScale)
        } completion: {
            clipper.removeFromSuperview()
        }
        // It fades as it lands, so the real button is what's left.
        UIView.animate(withDuration: 0.22, delay: 0.16, options: [.curveEaseIn]) {
            clipper.alpha = 0
        }
    }

    /// The bar and state follow (same as the ⌄ button); the motion is done
    /// by whoever called this. Search's stack goes back off screen, ready to
    /// rise next time.
    private func finishClosingSearch() {
        let stackView = searchStack.view!
        resetSearchPull()
        stackView.frame = view.bounds.offsetBy(dx: 0, dy: view.bounds.height)
        navigator.closeSearch()
    }

    /// The scroll view under the finger that scrolls vertically, if any.
    private static func verticalScroller(at point: CGPoint, in root: UIView) -> UIScrollView? {
        var candidate = root.hitTest(point, with: nil)
        while let v = candidate, v !== root {
            if let scrollView = v as? UIScrollView,
               scrollView.contentSize.width <= scrollView.bounds.width + 1 {
                return scrollView
            }
            candidate = v.superview
        }
        return nil
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MainContainerController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === searchPan else { return true }
        return shouldBeginSearchPan()
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Let the screen's scroll begin too; .began cancels it.
        gestureRecognizer === searchPan && otherGestureRecognizer.view is UIScrollView
    }

    /// Pulling down on Search's first screen, when its list is at the top
    /// (not while typing: that drag just drops the keyboard).
    private func shouldBeginSearchPan() -> Bool {
        guard current === searchStack, tabUnderSearch == nil,
              searchStack.viewControllers.count == 1,
              !navigator.isSearching else { return false }

        let velocity = searchPan.velocity(in: view)
        guard velocity.y > 0, velocity.y > abs(velocity.x) * 1.2 else { return false }

        let location = searchPan.location(in: view)
        if let scrollView = Self.verticalScroller(at: location, in: view) {
            let top = -scrollView.adjustedContentInset.top
            return scrollView.contentOffset.y <= top + 1
        }
        return true
    }
}

// MARK: - UINavigationControllerDelegate

extension MainContainerController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
        // No large titles: every screen uses the standard bar, title centered.
        viewController.navigationItem.largeTitleDisplayMode = .never

        if navigationController === current {
            updateBottomBarVisibility(showing: viewController, in: navigationController)
        }

        // A back swipe that gets cancelled leaves the screen that was on top:
        // put its bottom bar state back.
        if let coordinator = navigationController.transitionCoordinator, coordinator.isInteractive {
            coordinator.notifyWhenInteractionChanges { [weak self] context in
                guard context.isCancelled, let from = context.viewController(forKey: .from) else { return }
                self?.updateBottomBarVisibility(showing: from, in: navigationController)
            }
        }
    }

    /// Screens opened from Search (a category, a podcast) drop the search
    /// field: there it has nothing to search, and Search has no tabs. The bar
    /// keeps only the mini player, when something is playing (BottomBarLayout).
    private func updateBottomBarVisibility(showing viewController: UIViewController?,
                                           in stack: UINavigationController) {
        let isSearchDetail = stack === searchStack && viewController !== searchController
        if navigator.hidesBottomBar != isSearchDetail {
            navigator.hidesBottomBar = isSearchDetail
        }
        // A podcast's page, from any stack: only the mini player (no search).
        let isPodcastPage = viewController is EpisodesController
        if navigator.isOnPodcastPage != isPodcastPage {
            navigator.isOnPodcastPage = isPodcastPage
        }
        // An episode's page: no bar, not even the mini player.
        let isEpisodePage = viewController is EpisodeDetailController
        if navigator.hidesBarCompletely != isEpisodePage {
            navigator.hidesBarCompletely = isEpisodePage
        }
    }

}
