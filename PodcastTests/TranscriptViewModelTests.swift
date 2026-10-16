//
//  TranscriptViewModelTests.swift
//  PodcastTests
//

import Testing
import SwiftUI
@testable import Podcast

@MainActor
@Suite("TranscriptViewModel subtitles")
struct TranscriptViewModelTests {

    private let sut = TranscriptViewModel()

    init() {
        sut.segments = [
            LocalTranscriptSegment(text: "Uno.", startTime: 0, endTime: 4),
            LocalTranscriptSegment(text: "Dos.", startTime: 4, endTime: 9),
            LocalTranscriptSegment(text: "Tres.", startTime: 9, endTime: 15),
        ]
    }

    @Test("Before the first sentence starts, the subtitle shows the first one")
    func beforeStart() {
        #expect(sut.displayedSegment?.text == "Uno.")
        #expect(sut.previousSegment == nil)
    }

    @Test("The first sentence has nothing above it")
    func firstSentence() {
        sut.updateCurrentSegment(playbackSeconds: 2)
        #expect(sut.displayedSegment?.text == "Uno.")
        #expect(sut.previousSegment == nil)
    }

    @Test("Later sentences show the one before, faint above")
    func laterSentence() {
        sut.updateCurrentSegment(playbackSeconds: 10)
        #expect(sut.displayedSegment?.text == "Tres.")
        #expect(sut.previousSegment?.text == "Dos.")
    }

    @Test("ReadingTheme toggles and maps to a color scheme")
    func theme() {
        #expect(ReadingTheme.night.toggled == .paper)
        #expect(ReadingTheme.paper.toggled == .night)
        #expect(ReadingTheme.night.colorScheme == .dark)
    }
}
