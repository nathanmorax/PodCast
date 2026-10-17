//
//  NavigationContainer.swift
//  Podcast
//

import UIKit

/// What AppNavigator needs from the screen that holds the navigation stacks.
/// MainContainerController in the app; a fake in the tests.
@MainActor
protocol NavigationContainer: AnyObject {
    var searchStack: UINavigationController { get }
    func stack(for tab: AppTab) -> UINavigationController?
    func show(_ tab: AppTab)
    func showSearch()
    func focusSearch()
}
