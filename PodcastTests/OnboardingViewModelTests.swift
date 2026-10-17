//
//  OnboardingViewModelTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

@MainActor
@Suite("OnboardingViewModel")
struct OnboardingViewModelTests {

    private let catalog = Genre.podcastCatalog

    @Test("Needs at least 3 genres to continue")
    func minimum() {
        let sut = OnboardingViewModel()
        sut.toggle(catalog[0])
        sut.toggle(catalog[1])
        #expect(!sut.canContinue)
        sut.toggle(catalog[2])
        #expect(sut.canContinue)
    }

    @Test("Tapping again deselects")
    func toggleOff() {
        let sut = OnboardingViewModel()
        sut.toggle(catalog[0])
        sut.toggle(catalog[0])
        #expect(!sut.isSelected(catalog[0]))
        #expect(sut.selectedIDs.isEmpty)
    }

    @Test("Continue saves the picks in tap order")
    func finish() {
        let interests = InterestsManager(userDefaults: .isolated())
        let sut = OnboardingViewModel()
        for genre in [catalog[4], catalog[0], catalog[8]] { sut.toggle(genre) }

        sut.finish(into: interests)

        #expect(interests.genreIDs == [catalog[4].id, catalog[0].id, catalog[8].id])
        #expect(!interests.needsOnboarding)
    }

    @Test("Continue does nothing with fewer than 3")
    func finishTooFew() {
        let interests = InterestsManager(userDefaults: .isolated())
        let sut = OnboardingViewModel()
        sut.toggle(catalog[0])
        sut.finish(into: interests)
        #expect(interests.needsOnboarding)
    }

    @Test("Editing starts with the previous picks")
    func preselected() {
        let sut = OnboardingViewModel(selectedIDs: ["1303", "unknown"])
        #expect(sut.selectedIDs == ["1303"])
    }

    @Test("The catalog has unique ids")
    func catalogIDs() {
        #expect(Set(catalog.map(\.id)).count == catalog.count)
    }
}
