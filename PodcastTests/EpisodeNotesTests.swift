//
//  EpisodeNotesTests.swift
//  PodcastTests
//

import Testing
@testable import Podcast

@Suite("EpisodeNotes")
struct EpisodeNotesTests {

    @Test("The first sentence becomes the quote, the rest the body")
    func split() {
        let notes = EpisodeNotes("Elegir cansa más de lo que creemos. Hablamos con una neuroeconomista.")
        #expect(notes.quote == "Elegir cansa más de lo que creemos.")
        #expect(notes.rest == "Hablamos con una neuroeconomista.")
    }

    @Test("A single sentence has no quote")
    func single() {
        let notes = EpisodeNotes("Solo una frase sobre el episodio.")
        #expect(notes.quote == nil)
        #expect(notes.rest == "Solo una frase sobre el episodio.")
    }

    @Test("A very long or very short first sentence isn't quoted")
    func lengths() {
        let long = String(repeating: "palabra ", count: 40) + ". Resto."
        #expect(EpisodeNotes(long).quote == nil)
        #expect(EpisodeNotes("Hola. Resto del texto aquí.").quote == nil)
    }

    @Test("Empty notes stay empty")
    func empty() {
        let notes = EpisodeNotes("   ")
        #expect(notes.quote == nil)
        #expect(notes.rest.isEmpty)
    }
}
