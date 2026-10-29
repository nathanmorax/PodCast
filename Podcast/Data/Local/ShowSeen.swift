//
//  ShowSeen.swift
//  Podcast
//

import Foundation
import Observation

/// When each followed show's page was last opened: its episodes published
/// after that are "new" on its cover in Home (they peek out from behind it).
/// Opening the Inbox also counts as having seen them (InboxSeen), so the
/// later of the two wins. Saved between launches.
@MainActor
@Observable
final class ShowSeen {

    static let shared = ShowSeen()

    /// trackId → when its page was last opened.
    private(set) var lastSeen: [Int: Date]

    @ObservationIgnored private let defaults: UserDefaults
    private static let key = "shows.lastSeen"

    /// - Parameter defaults: where it's saved (tests pass their own suite).
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let saved = defaults.dictionary(forKey: Self.key) as? [String: Date] ?? [:]
        lastSeen = Dictionary(uniqueKeysWithValues: saved.compactMap { key, date in
            Int(key).map { ($0, date) }
        })
    }

    /// Opening a show's page: its episodes up to now have been seen.
    func markSeen(_ trackId: Int, at date: Date = .now) {
        lastSeen[trackId] = date
        let stored = Dictionary(uniqueKeysWithValues: lastSeen.map { (String($0.key), $0.value) })
        defaults.set(stored, forKey: Self.key)
    }
}
