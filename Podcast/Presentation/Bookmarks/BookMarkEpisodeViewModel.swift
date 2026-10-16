//
//  BookMarkEpisodeViewModel.swift
//  Podcast
//
//  Created by Jonathan Mora on 04/06/26.
//
import SwiftUI

@Observable
class BookMarkEpisodeViewModel {
    
    private let bookmarkManager: BookMarkEpisodeManager
    
    var episodes: [Episode] { bookmarkManager.episodes }

    init(
        bookmarkManagerEpisode: BookMarkEpisodeManager = .shared,

    ) {
        self.bookmarkManager = bookmarkManagerEpisode
    }
}
