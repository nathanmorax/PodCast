//
//  BookMarkEpisodeViewModel.swift
//  Podcast
//
//  Created by Jonathan Mora on 04/06/26.
//

import Observation

/// @MainActor: it reads BookMarkEpisodeManager (main actor) and feeds the
/// Saved screen. Its `.shared` default is now evaluated on the same actor.
@MainActor
@Observable
final class BookMarkEpisodeViewModel {

    @ObservationIgnored private let bookmarkManager: BookMarkEpisodeManager

    var episodes: [Episode] { bookmarkManager.episodes }

    init(bookmarkManagerEpisode: BookMarkEpisodeManager = .shared) {
        self.bookmarkManager = bookmarkManagerEpisode
    }
}
