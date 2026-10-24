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
/// hairline). It shows no title, the page's first section ("Library") is
/// the title, and holds the Inbox tray on the right.
final class HomeController: UIViewController {

    /// Shared by the page ("For you") and the Inbox button: one download.
    private lazy var forYou = ForYouViewModel(cache: .standard)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Kept for VoiceOver and the back button's menu; not shown.
        title = String(localized: "Library")
        navigationItem.titleView = UIView()
        navigationItem.largeTitleDisplayMode = .never
        setupInboxButton()
        // Same gray as the content, so the large title area doesn't show a
        // white band above it.
        view.backgroundColor = ColorName.screenBackground.uiColor
        setupHosting()
    }

    private func setupHosting() {
        let home = HomeView(
            forYou: forYou,
            onOpenPodcast: { [weak self] podcast in self?.open(podcast) },
            onOpenEpisode: { [weak self] episode, podcast in
                self?.pushZooming(
                    EpisodeDetailController(episode: episode, podcastName: podcast.trackName),
                    from: .episode(episode.streamUrl, section: .forYou)
                )
            },
            onOpenPlayedEpisode: { [weak self] episode in
                self?.pushZooming(
                    EpisodeDetailController(episode: episode, podcastName: nil),
                    from: .episode(episode.streamUrl, section: .recentlyPlayed)
                )
            },
            onSearch: { AppNavigator.shared.showSearch() },
            onOpenFollowing: { [weak self] in
                self?.pushZooming(FollowingController(), from: .collection(.following))
            },
            onOpenFavorites: { [weak self] in
                self?.pushZooming(SavedEpisodesController(.favorites), from: .collection(.favorites))
            },
            onOpenDownloads: { [weak self] in
                self?.pushZooming(SavedEpisodesController(.downloads), from: .collection(.downloads))
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

    /// The tray, top right. SwiftUI (for its badge) in a bar button; its
    /// view is also what the Inbox zooms out of and back into.
    private func setupInboxButton() {
        let button = UIHostingController(rootView: InboxBarButton(forYou: forYou) { [weak self] items in
            self?.pushZooming(InboxController(items: items), from: .collection(.inbox))
        })
        button.sizingOptions = .intrinsicContentSize
        button.view.backgroundColor = .clear
        addChild(button)
        let item = UIBarButtonItem(customView: button.view)
        // Its own look (tray + badge): no glass capsule behind it.
        item.hidesSharedBackground = true
        navigationItem.rightBarButtonItem = item
        button.didMove(toParent: self)
        ZoomSources.shared.register(button.view, id: .collection(.inbox), cornerRadius: 22)
    }

    /// Everything Home opens zooms out of its item and closes back into it
    /// (pushZooming): podcasts, episodes, and the collections.
    private func open(_ podcast: Podcast) {
        pushZooming(EpisodesController(podcast: podcast), from: .podcast(podcast.id))
    }
}
