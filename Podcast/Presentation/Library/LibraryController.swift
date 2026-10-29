//
//  LibraryController.swift
//  Podcast
//
import UIKit
import SwiftUI

/// The Library (New · Saved · Downloads · History), pushed from the books
/// button in Home's navigation bar (or "Show all" on New episodes). Its
/// title is set in serif capitals, like a magazine's section name.
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
        navigationItem.titleView = Self.serifTitle(String(localized: "Library"))
        seen.markSeen()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ColorName.screenBackground.uiColor
        let library = LibraryView(followingFeed: followingFeed, tab: initialTab) { [weak self] episode in
            // Tapping a card: its details in a sheet (▶ plays it instead).
            self?.presentEpisodeSheet(episode)
        }
        embedFullScreen(UIHostingController(rootView: library))
    }

    /// "LIBRARY" in New York, growing with the text size.
    private static func serifTitle(_ text: String) -> UILabel {
        let label = UILabel()
        let base = UIFont.preferredFont(forTextStyle: .title3)
        let descriptor = base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor
        let font = UIFont(descriptor: descriptor, size: 0)
        label.attributedText = NSAttributedString(
            string: text.uppercased(),
            attributes: [.kern: 1.2, .font: font]
        )
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ColorName.ink.uiColor
        label.accessibilityTraits = .header
        return label
    }
}
