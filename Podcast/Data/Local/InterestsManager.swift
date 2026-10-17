//
//  InterestsManager.swift
//  Podcast
//

import Foundation
import Observation

/// The genres the listener chose in onboarding, saved in UserDefaults.
/// Home reads them to build "For you". Only ids are stored: names come from
/// `Genre.podcastCatalog`, so they follow the device language.
@MainActor
@Observable
final class InterestsManager {

    static let shared = InterestsManager()

    /// In the order they were tapped (the first ones go first in Home).
    private(set) var genreIDs: [String]
    private(set) var hasCompletedOnboarding: Bool
    /// The listener reopened the screen from Home ("Edit").
    private(set) var isEditing = false

    @ObservationIgnored private let userDefaults: UserDefaults

    private enum Key {
        static let genres = "interest_genre_ids"
        static let completed = "has_completed_onboarding"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.genreIDs = userDefaults.stringArray(forKey: Key.genres) ?? []
        self.hasCompletedOnboarding = userDefaults.bool(forKey: Key.completed)
    }

    var genres: [Genre] { genreIDs.compactMap(Genre.catalog(id:)) }

    /// Shows the onboarding screen (first launch, or editing from Home).
    var needsOnboarding: Bool { !hasCompletedOnboarding || isEditing }

    func save(_ ids: [String]) {
        genreIDs = ids
        finish()
    }

    /// Closes the screen when it was opened from Home ("Cancel"), keeping
    /// the picks it had. (There's no skip on first launch.)
    func skip() {
        finish()
    }

    /// At most this many genres are learned from listening.
    static let maxGenres = 8

    /// Listening teaches Home: the genre of a podcast the listener played is
    /// added to their interests, after the ones they picked. Fixes a careless
    /// pick at onboarding over time.
    func learn(genreID: String) {
        guard hasCompletedOnboarding,
              Genre.catalog(id: genreID) != nil,
              !genreIDs.contains(genreID),
              genreIDs.count < Self.maxGenres else { return }
        genreIDs.append(genreID)
        userDefaults.set(genreIDs, forKey: Key.genres)
    }

    func edit() {
        isEditing = true
    }

    private func finish() {
        hasCompletedOnboarding = true
        isEditing = false
        userDefaults.set(genreIDs, forKey: Key.genres)
        userDefaults.set(true, forKey: Key.completed)
    }
}
