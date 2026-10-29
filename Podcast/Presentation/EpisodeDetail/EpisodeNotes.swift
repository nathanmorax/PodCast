//
//  EpisodeNotes.swift
//  Podcast
//

import SwiftUI

/// Show notes split for the article layout: the first sentence becomes the
/// quote (when it's a reasonable length), the rest is the body.
struct EpisodeNotes: Equatable {
    let quote: String?
    let rest: String

    static let maxQuoteLength = 180

    init(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var end: String.Index?
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { _, range, _, stop in
            end = range.upperBound
            stop = true
        }
        guard let end, end < text.endIndex else {
            // One sentence or nothing: no quote, just the text.
            quote = nil
            rest = text
            return
        }
        let first = text[..<end].trimmingCharacters(in: .whitespacesAndNewlines)
        guard first.count <= Self.maxQuoteLength, first.count >= 20 else {
            quote = nil
            rest = text
            return
        }
        quote = first
        rest = text[end...].trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
