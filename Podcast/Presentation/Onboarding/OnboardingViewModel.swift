//
//  OnboardingViewModel.swift
//  Podcast
//

import Observation

/// Which genres are picked on the onboarding screen. Nothing is saved until
/// "Continue" (or "Skip").
@MainActor
@Observable
final class OnboardingViewModel {

    static let minimumSelection = 3

    let genres: [Genre]
    /// In tap order, so the first picks become Home's first rows.
    private(set) var selectedIDs: [String]

    init(genres: [Genre] = Genre.podcastCatalog, selectedIDs: [String] = []) {
        self.genres = genres
        self.selectedIDs = selectedIDs.filter { id in genres.contains { $0.id == id } }
    }

    var canContinue: Bool { selectedIDs.count >= Self.minimumSelection }

    func isSelected(_ genre: Genre) -> Bool {
        selectedIDs.contains(genre.id)
    }

    func toggle(_ genre: Genre) {
        if let index = selectedIDs.firstIndex(of: genre.id) {
            selectedIDs.remove(at: index)
        } else {
            selectedIDs.append(genre.id)
        }
    }

    func finish(into interests: InterestsManager) {
        guard canContinue else { return }
        interests.save(selectedIDs)
    }

    func skip(into interests: InterestsManager) {
        interests.skip()
    }
}
