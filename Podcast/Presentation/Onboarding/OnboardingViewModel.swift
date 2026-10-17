//
//  OnboardingViewModel.swift
//  Podcast
//

import Observation

/// Which genres are picked on the onboarding screen. Nothing is saved until
/// "Continue". There's no skip: at least one genre, or "Choose for me".
@MainActor
@Observable
final class OnboardingViewModel {

    /// One is enough for a "For you" row, and people pick it for real
    /// (asking for 3 makes them tap anything to get through).
    static let minimumSelection = 1

    /// "Choose for me": the most listened genres (Comedy, News, True Crime).
    static let popularIDs = ["1303", "1489", "1488"]

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

    /// Picks the popular genres (keeps any the listener already chose);
    /// they can still change them before continuing.
    func chooseForMe() {
        for id in Self.popularIDs where !selectedIDs.contains(id) && genres.contains(where: { $0.id == id }) {
            selectedIDs.append(id)
        }
    }

    /// Closing without changes (only when editing from Home).
    func cancel(into interests: InterestsManager) {
        interests.skip()
    }
}
