//
//  SearchExploreController.swift
//  Podcast
//

import UIKit
import SwiftUI

/// What Search shows before you type (SearchExploreView). A child of
/// PodcastSearchContainerController, which decides what a tap opens.
final class SearchExploreController: UIViewController {

    var onOpenPodcast: ((Podcast) -> Void)?
    var onSelectGenre: ((Genre) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        let explore = SearchExploreView(
            onOpenPodcast: { [weak self] in self?.onOpenPodcast?($0) },
            onSelectGenre: { [weak self] in self?.onSelectGenre?($0) }
        )
        embedFullScreen(UIHostingController(rootView: explore))
    }
}
