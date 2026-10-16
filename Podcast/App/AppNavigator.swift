//
//  AppNavigator.swift
//  Podcast
//

import UIKit
import Observation

/// App-level navigation state shared between UIKit (the navigation stack) and
/// SwiftUI (the bottom bar in RootView).
@MainActor
@Observable
final class AppNavigator {

    static let shared = AppNavigator()

    /// True while the search field has the keyboard: the bottom bar steps aside.
    var isSearching = false

    @ObservationIgnored
    weak var navigationController: UINavigationController?

    /// Opens Search on top of the Library (or just focuses the field if it's
    /// already the visible screen).
    func showSearch() {
        guard let navigationController else { return }
        if let search = navigationController.topViewController as? PodcastSearchContainerController {
            search.focusSearchField()
            return
        }
        let search = PodcastSearchContainerController()
        search.focusesSearchOnAppear = true
        navigationController.pushViewController(search, animated: true)
    }
}
