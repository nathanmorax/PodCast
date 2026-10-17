//
//  EpisodeChapter.swift
//  Podcast
//

import Foundation

/// A chapter of an episode: where it starts and its title.
struct EpisodeChapter: Identifiable, Hashable, Sendable {
    let start: TimeInterval
    let title: String
    var id: TimeInterval { start }
}

extension EpisodeChapter {

    /// Chapters written in the show notes, the way most podcasts do it:
    /// "00:00 Intro", "(12:05) The trap", "1:02:30 - Questions", "[4:30] Tomorrow".
    ///
    /// To avoid false positives (a time mentioned in a sentence) it needs at
    /// least three timestamps, in increasing order; otherwise there are none.
    static func parse(showNotes: String) -> [EpisodeChapter] {
        let pattern = #"(?<![\d:])(?:(\d{1,2}):)?(\d{1,2}):(\d{2})(?![\d:])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let text = showNotes as NSString
        let matches = regex.matches(in: showNotes, range: NSRange(location: 0, length: text.length))
        guard matches.count >= 3 else { return [] }

        var chapters: [EpisodeChapter] = []
        for (index, match) in matches.enumerated() {
            func number(_ group: Int) -> Double {
                let range = match.range(at: group)
                guard range.location != NSNotFound else { return 0 }
                return Double(text.substring(with: range)) ?? 0
            }
            let start = number(1) * 3600 + number(2) * 60 + number(3)

            let titleStart = match.range.location + match.range.length
            let titleEnd = index + 1 < matches.count ? matches[index + 1].range.location : text.length
            let raw = text.substring(with: NSRange(location: titleStart, length: max(titleEnd - titleStart, 0)))
            let title = cleanTitle(raw)
            guard !title.isEmpty else { continue }

            if let last = chapters.last, start <= last.start { return [] }
            chapters.append(EpisodeChapter(start: start, title: title))
        }
        return chapters.count >= 3 ? chapters : []
    }

    /// First line only, without the separators around timestamps.
    private static func cleanTitle(_ raw: String) -> String {
        let separators = CharacterSet(charactersIn: " \t-–—:)]|•.([")
        let firstLine = raw
            .trimmingCharacters(in: separators.union(.whitespacesAndNewlines))
            .components(separatedBy: .newlines)
            .first ?? ""
        let title = firstLine.trimmingCharacters(in: separators.union(.whitespaces))
        return String(title.prefix(80))
    }
}
