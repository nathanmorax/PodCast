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
final class MainContainerController: UIViewController {

    private let stacks: [AppTab: UINavigationController]
    let searchController = PodcastSearchContainerController()
    let searchStack: UINavigationController
    private let scrollTracker = BottomBarScrollTracker(navigator: .shared)
    private weak var current: UINavigationController?

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
        show(AppNavigator.shared.selectedTab)
    }

    func show(_ tab: AppTab) {
        guard let next = stacks[tab] else { return }
        display(next)
    }

    /// Shows Search's stack; the keyboard comes up once it's on screen.
    func showSearch() {
        searchController.focusesSearchOnAppear = true
        display(searchStack)
    }

    private func display(_ next: UINavigationController) {
        guard next !== current else { return }

        if let current {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        addChild(next)
        next.view.frame = view.bounds
        next.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(next.view)
        next.didMove(toParent: self)
        current = next

        if let top = next.topViewController {
            scrollTracker.track(top)
        }
        setNeedsStatusBarAppearanceUpdate()
    }

    override var childForStatusBarStyle: UIViewController? { current }
}

// MARK: - UINavigationControllerDelegate

extension MainContainerController: UINavigationControllerDelegate {

    func navigationController(_ navigationController: UINavigationController,
                              willShow viewController: UIViewController,
                              animated: Bool) {
        // Home draws its own big title, so its root hides the navigation bar.
        navigationController.setNavigationBarHidden(viewController is HomeController, animated: animated)

        // A back swipe that gets cancelled must restore the bar of the screen
        // that stays.
        if let coordinator = navigationController.transitionCoordinator, coordinator.isInteractive {
            coordinator.notifyWhenInteractionChanges { context in
                guard context.isCancelled, let from = context.viewController(forKey: .from) else { return }
                navigationController.setNavigationBarHidden(from is HomeController, animated: true)
            }
        }
    }

    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        guard navigationController === current else { return }
        scrollTracker.track(viewController)
    }
}
