//
//  LibraryController.swift
//  Podcast
//
import UIKit
import SwiftUI

/// The Library (New · Saved · Downloads · History), pushed from the books
/// button in Home's navigation bar (or "Show all" on New episodes). Its
/// title is the page's own (LIBRARY in tall capitals, next to the layout
/// picker), so the bar shows only the back button.
///
/// It replaces the Inbox: opening it marks the new episodes as seen, so the
/// button's badge goes away.
final class LibraryController: UIViewController {

    private let followingFeed: FollowingFeedViewModel
    private let initialTab: LibraryTab

    init(followingFeed: FollowingFeedViewModel, tab: LibraryTab = .new, seen: InboxSeen = .shared) {
        self.followingFeed = followingFeed
        self.initialTab = tab
        super.init(nibName: nil, bundle: nil)
        title = String(localized: "Library")
        navigationItem.largeTitleDisplayMode = .never
        // `title` still names it in the back button's menu.
        navigationItem.titleView = UIView()
        seen.markSeen()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorName.screenBackground.uiColor
        let library = LibraryView(followingFeed: followingFeed, tab: initialTab) { [weak self] item in
            // Tapping an episode: its screen, like everywhere else (▶ plays
            // it instead).
            self?.navigationController?.pushViewController(
                EpisodeDetailController(episode: item.episode, podcast: item.podcast),
                animated: true
            )
        }
        embedFullScreen(UIHostingController(rootView: library))
    }
}
