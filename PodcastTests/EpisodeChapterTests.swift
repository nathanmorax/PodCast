//
//  EpisodeChapterTests.swift
//  PodcastTests
//

import Testing
@testable import Podcast

@Suite("EpisodeChapter.parse")
struct EpisodeChapterTests {

    @Test("Reads the common show-notes formats")
    func formats() {
        let notes = """
        In this episode:
        00:00 Intro
        (04:30) Mañana, siempre mañana
        [9:10] - La trampa del alivio
        1:02:05 – Preguntas
        """
        let chapters = EpisodeChapter.parse(showNotes: notes)
        #expect(chapters.map(\.start) == [0, 270, 550, 3725])
        #expect(chapters.map(\.title) == ["Intro", "Mañana, siempre mañana", "La trampa del alivio", "Preguntas"])
    }

    @Test("Fewer than three timestamps are not chapters")
    func tooFew() {
        let notes = "We met at 10:30 and talked until 12:00."
        #expect(EpisodeChapter.parse(showNotes: notes).isEmpty)
    }

    @Test("Out of order timestamps are not chapters")
    func outOfOrder() {
        let notes = "05:00 B\n01:00 A\n09:00 C"
        #expect(EpisodeChapter.parse(showNotes: notes).isEmpty)
    }

    @Test("No timestamps, no chapters")
    func none() {
        #expect(EpisodeChapter.parse(showNotes: "Just a description.").isEmpty)
    }
}

@Suite("Show notes")
struct ShowNotesTests {
    @Test("HTML show notes keep one line per paragraph, so chapters are found")
    func htmlNotes() {
        let html = "<p>Hoy:</p><p>00:00 Intro</p><p>04:30 Mañana &amp; siempre</p><br>09:10 La trampa"
        let text = html.plainTextFromHTML()
        let chapters = EpisodeChapter.parse(showNotes: text)
        #expect(chapters.map(\.title) == ["Intro", "Mañana & siempre", "La trampa"])
    }

    @Test("Chapters come from the full notes, not the short subtitle")
    func source() {
        let episode = Episode(
            title: "T", author: "A", pubDate: .now, description: "Short subtitle",
            streamUrl: "https://example.com/1.mp3", showNotes: "00:00 A\n01:00 B\n02:00 C"
        )
        #expect(EpisodeChapter.parse(showNotes: episode.chapterSource).count == 3)
    }
}
