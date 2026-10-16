//
//  MainNavigation.swift
//  Podcast
//

import SwiftUI
import UIKit

/// Wraps MainContainerController for RootView.
struct MainNavigationRepresentable: UIViewControllerRepresentable {

    /// Space reserved at the bottom for the SwiftUI bar, so lists end above it
    /// instead of scrolling underneath.
    var bottomInset: CGFloat

    func makeUIViewController(context: Context) -> MainContainerController {
        let container = MainContainerController()
        AppNavigator.shared.container = container
        return container
    }

    func updateUIViewController(_ container: MainContainerController, context: Context) {
        guard container.additionalSafeAreaInsets.bottom != bottomInset else { return }
        UIView.animate(withDuration: 0.3) {
            // Propagates to both stacks and every pushed screen.
            container.additionalSafeAreaInsets.bottom = bottomInset
            container.view.layoutIfNeeded()
        }
    }
}

/// One navigation stack per tab (Inicio, Biblioteca). Only the selected one is
/// on screen; the other keeps its history for when you come back. There is no
/// UITabBar: the bottom of the screen belongs to RootView's BottomBar.
final class MainContainerController: UIViewController {

    private let stacks: [AppTab: UINavigationController]
    private let scrollTracker = BottomBarScrollTracker(navigator: .shared)
    private weak var current: UINavigationController?

    init() {
        var stacks: [AppTab: UINavigationController] = [:]
        for tab in AppTab.allCases {
            let navigation = UINavigationController(rootViewController: Self.makeRoot(for: tab))
            navigation.navigationBar.tintColor = .label
            stacks[tab] = navigation
        }
        self.stacks = stacks
        super.init(nibName: nil, bundle: nil)
        stacks.values.forEach { $0.delegate = self }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        guard let next = stacks[tab], next !== current else { return }

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
