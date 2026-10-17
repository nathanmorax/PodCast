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

    /// "Skip": don't ask again; keeps whatever was chosen before.
    func skip() {
        finish()
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
