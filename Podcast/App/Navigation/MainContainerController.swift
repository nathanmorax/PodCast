//
//  MainContainerController.swift
//  Podcast
//

import UIKit

/// One navigation stack per tab (Inicio, Biblioteca) plus one for Search.
/// Only one is on screen; the others keep their history for when you come
/// back. There is no UITabBar: the bottom of the screen belongs to RootView's
/// BottomBar.
///
/// Search is the *root* of its own stack instead of being pushed on top of a
/// tab, so it has no back arrow. Opening a podcast from the results still
/// pushes (with its back arrow) inside Search's stack.
///
/// Swiping sideways on a tab's first screen slides to the other tab, with the
/// content following the finger (see "Swipe between tabs").
final class MainContainerController: UIViewController, NavigationContainer {

    private let stacks: [AppTab: UINavigationController]
    let searchController = PodcastSearchContainerController()
    let searchStack: UINavigationController
    private let scrollTracker = BottomBarScrollTracker(navigator: .shared)
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
        navigation.navigationBar.tintColor = .label
        // Standard (inline) titles everywhere: no large titles, so every
        // header sits at the same height.
        navigation.navigationBar.prefersLargeTitles = false
        return navigation
    }

    private static func makeRoot(for tab: AppTab) -> UIViewController {
        switch tab {
        case .home:    HomeController()
        case .library: LibraryController()
        }
    }

    func stack(for tab: AppTab) -> UINavigationController? {
        stacks[tab]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addGestureRecognizer(tabPan)
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

    /// Shows Search's stack right away (no slide): the keyboard coming up is
    /// the only motion, so nothing competes with it. A slide-up used to run at
    /// the same time as the keyboard and the bar changing shape, and it
    /// stuttered.
    func showSearch() {
        searchController.focusesSearchOnAppear = true
        display(searchStack)
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
        if let top = stack.topViewController {
            scrollTracker.track(top)
        }
        setNeedsStatusBarAppearanceUpdate()
    }

    override var childForStatusBarStyle: UIViewController? { current }

    // MARK: - Swipe between tabs

    /// A swipe in progress: the tab it goes to and the two stacks moving.
    private struct TabSwipe {
        let tab: AppTab
        let outgoing: UINavigationController
        let incoming: UINavigationController
        let towardNext: Bool
    }

    private var tabSwipe: TabSwipe?

    private lazy var tabPan: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleTabPan(_:)))
        pan.delegate = self
        return pan
    }()

    @objc private func handleTabPan(_ pan: UIPanGestureRecognizer) {
        let width = view.bounds.width
        switch pan.state {
        case .began:
            // Finger to the left → the tab on the right (like Safari's tab bar).
            let towardNext = pan.velocity(in: view).x < 0
            guard let outgoing = current,
                  let tab = navigator.tab(forSwipeTowardNext: towardNext),
                  let incoming = stacks[tab] else { return }
            cancelScrolling(at: pan.location(in: view))
            // The next tab waits just off screen, on the side it comes from.
            embed(incoming, frame: view.bounds.offsetBy(dx: towardNext ? width : -width, dy: 0))
            tabSwipe = TabSwipe(tab: tab, outgoing: outgoing, incoming: incoming, towardNext: towardNext)

        case .changed:
            guard let swipe = tabSwipe else { return }
            let x = pan.translation(in: view).x
            // Only toward the other tab, never past it.
            let dx = swipe.towardNext ? min(0, max(-width, x)) : max(0, min(width, x))
            move(swipe, by: dx)

        case .ended, .cancelled, .failed:
            guard let swipe = tabSwipe else { return }
            tabSwipe = nil
            let x = pan.translation(in: view).x
            let velocity = pan.velocity(in: view).x
            let rightDirection = (x < 0) == swipe.towardNext
            let farEnough = abs(x) > width * 0.35
            let flicked = abs(velocity) > 600 && (velocity < 0) == swipe.towardNext
            let completes = pan.state == .ended && rightDirection && (farEnough || flicked)
            finish(swipe, completes: completes)

        default:
            break
        }
    }

    private func move(_ swipe: TabSwipe, by dx: CGFloat) {
        let transform = CGAffineTransform(translationX: dx, y: 0)
        swipe.outgoing.view.transform = transform
        swipe.incoming.view.transform = transform
    }

    /// Lets go: slides to the other tab, or back if the swipe was too short.
    private func finish(_ swipe: TabSwipe, completes: Bool) {
        let width = view.bounds.width
        let target: CGFloat = completes ? (swipe.towardNext ? -width : width) : 0
        UIView.animate(AppAnimation.gestureRelease) {
            self.move(swipe, by: target)
        } completion: {
            swipe.outgoing.view.transform = .identity
            swipe.incoming.view.transform = .identity
            guard completes else {
                self.remove(swipe.incoming)
                return
            }
            self.remove(swipe.outgoing)
            swipe.incoming.view.frame = self.view.bounds
            self.didBecomeCurrent(swipe.incoming)
            // Updates the bar (selected tab + haptic). show(_:) sees the stack
            // is already on screen and does nothing.
            self.navigator.select(swipe.tab)
        }
    }

    /// The screen's own scroll starts too (vertical): stop it, the swipe wins.
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
            searchStack.view.transform = CGAffineTransform(translationX: 0, y: y)

        case .ended, .cancelled, .failed:
            guard let under = tabUnderSearch else { return }
            tabUnderSearch = nil
            let y = pan.translation(in: view).y
            let completes = pan.state == .ended && (y > height * 0.25 || pan.velocity(in: view).y > 800)
            UIView.animate(AppAnimation.gestureRelease) {
                self.searchStack.view.transform = completes
                    ? CGAffineTransform(translationX: 0, y: height)
                    : .identity
            } completion: {
                guard completes else {
                    self.searchStack.view.transform = .identity
                    self.removeIfHidden(under)
                    return
                }
                self.searchStack.view.transform = .identity
                self.searchStack.view.frame = self.view.bounds.offsetBy(dx: 0, dy: height)
                // Same as the ⌄ button: the bar and state follow; the slide
                // down is already done.
                self.navigator.closeSearch()
            }

        default:
            break
        }
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

    /// Rows that scroll sideways (your podcasts, recents) keep their swipe.
    private static func touchesHorizontalScroller(at point: CGPoint, in root: UIView) -> Bool {
        var candidate = root.hitTest(point, with: nil)
        while let v = candidate, v !== root {
            if let scrollView = v as? UIScrollView,
               scrollView.contentSize.width > scrollView.bounds.width + 1 {
                return true
            }
            candidate = v.superview
        }
        return false
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MainContainerController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === searchPan {
            return shouldBeginSearchPan()
        }
        guard gestureRecognizer === tabPan else { return true }
        // Only on a tab's first screen, not in Search or while typing.
        guard tabSwipe == nil,
              !navigator.isShowingSearch, !navigator.isSearching,
              let current, current.viewControllers.count == 1 else { return false }

        let velocity = tabPan.velocity(in: view)
        guard abs(velocity.x) > abs(velocity.y) * 1.5 else { return false }

        // The left edge is iOS's "back"; keep both edges free.
        let location = tabPan.location(in: view)
        guard location.x > 30, location.x < view.bounds.width - 30 else { return false }

        // Nothing past the first and last tab.
        guard navigator.tab(forSwipeTowardNext: velocity.x < 0) != nil else { return false }

        return !Self.touchesHorizontalScroller(at: location, in: view)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Let the screen's scroll begin too; .began cancels it.
        (gestureRecognizer === tabPan || gestureRecognizer === searchPan)
            && otherGestureRecognizer.view is UIScrollView
    }

    /// Pulling down on Search's first screen, when its list is at the top
    /// (not while typing: that drag just drops the keyboard).
    private func shouldBeginSearchPan() -> Bool {
        guard current === searchStack, tabUnderSearch == nil, tabSwipe == nil,
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
        // A podcast's page, from any tab: no bar, not even the mini player.
        let isPodcastPage = viewController is EpisodesController
        if navigator.hidesBarCompletely != isPodcastPage {
            navigator.hidesBarCompletely = isPodcastPage
        }
    }

    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        guard navigationController === current else { return }
        scrollTracker.track(viewController)
    }
}
