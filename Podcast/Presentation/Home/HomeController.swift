//
//  HomeController.swift
//  Podcast
//

import UIKit
import SwiftUI

/// Root of the Library tab. Hosts HomeView and pushes the screens it opens.
///
/// The navigation bar stays (hiding it here and showing it on every push
/// moved the next screen's content mid-transition, a jump plus the bar's
/// hairline). It shows the "TELL ME MORE" masthead on the left and the
/// Library button on the right.
final class HomeController: UIViewController {

    /// The followed podcasts' episodes: New episodes, the Library and its badge. The page
    /// loads it (HomeView), the button reads it.
    private lazy var followingFeed = FollowingFeedViewModel(cache: .standard)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Kept for VoiceOver and the back button's menu; not shown.
        title = String(localized: "Home")
        navigationItem.titleView = UIView()
        navigationItem.largeTitleDisplayMode = .never
        setupWordmark()
        setupLibraryButton()
        // Same gray as the content, so the large title area doesn't show a
        // white band above it.
        view.backgroundColor = ColorName.screenBackground.uiColor
        setupHosting()
    }

    private func setupHosting() {
        let home = HomeView(
            followingFeed: followingFeed,
            onOpenPodcast: { [weak self] podcast in self?.open(podcast) },
            onOpenEpisode: { [weak self] episode, podcast, section in
                self?.pushZooming(
                    EpisodeDetailController(episode: episode, podcast: podcast),
                    from: .episode(episode.streamUrl, section: section)
                )
            },
            onOpenPlayedEpisode: { [weak self] episode in
                self?.pushZooming(
                    EpisodeDetailController(episode: episode, podcast: nil),
                    from: .episode(episode.streamUrl, section: .recentlyPlayed)
                )
            },
            onOpenLibrary: { [weak self] tab in self?.openLibrary(tab: tab) },
            onSearch: { AppNavigator.shared.showSearch() },
            onOpenFollowing: { [weak self] in
                guard let self else { return }
                pushZooming(FollowingController(followingFeed: followingFeed), from: .collection(.following))
            }
        )
        let hosting = UIHostingController(rootView: home)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.backgroundColor = .clear
        addChild(hosting)
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)
    }

    /// "TELL ME MORE" on the left of the bar, in tall capitals like the
    /// feed's titles: the app's name as a masthead. No glass behind it
    /// (it's a title, not a button); it grows with the text size.
    private func setupWordmark() {
        let label = UILabel()
        let base = UIFont.systemFont(ofSize: 24, weight: .bold, width: .compressed)
        label.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: base, maximumPointSize: 32)
        label.adjustsFontForContentSizeCategory = true
        label.text = String(localized: "Tell me more").uppercased()
        label.textColor = ColorName.ink.uiColor
        label.accessibilityTraits = .header

        let item = UIBarButtonItem(customView: label)
        item.hidesSharedBackground = true
        navigationItem.leftBarButtonItem = item
    }

    /// Keeps the button's hosting controller alive (the bar only holds its view).
    private var libraryButtonHost: UIHostingController<LibraryBarButton>?

    /// The books button, top right: the Library (New · Saved · Downloads ·
    /// History), with a badge for what's new. SwiftUI (for the badge) in a
    /// bar button; its view is also what the Library zooms out of and back
    /// into.
    ///
    /// Not added as a child controller: the bar's views belong to the
    /// navigation controller, and UIKit crashes when a child of this screen
    /// ends up in there (UIViewControllerHierarchyInconsistency).
    private func setupLibraryButton() {
        let host = UIHostingController(rootView: LibraryBarButton(feed: followingFeed) { [weak self] in
            self?.openLibrary(tab: .new)
        })
        host.sizingOptions = .intrinsicContentSize
        host.view.backgroundColor = .clear
        libraryButtonHost = host

        // iOS 26: the bar's Liquid Glass capsule behind it, like the
        // episode page's ••• and the back button.
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: host.view)
        ZoomSources.shared.register(host.view, id: .collection(.library), cornerRadius: 22)
    }

    private func openLibrary(tab: LibraryTab) {
        pushZooming(
            LibraryController(followingFeed: followingFeed, tab: tab),
            from: .collection(.library)
        )
    }

    /// Everything Home opens zooms out of its item and closes back into it
    /// (pushZooming): podcasts, episodes, and the collections.
    private func open(_ podcast: Podcast) {
        pushZooming(EpisodesController(podcast: podcast), from: .podcast(podcast.id))
    }
}
