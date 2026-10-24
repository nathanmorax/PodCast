//
//  InboxSeen.swift
//  Podcast
//

import Foundation
import Observation

/// When the Inbox was last opened: episodes published after it are "new"
/// (the badge on the tray in Library). Saved between launches.
@MainActor
@Observable
final class InboxSeen {

    static let shared = InboxSeen()

    private(set) var lastSeen: Date

    @ObservationIgnored private let defaults: UserDefaults
    private static let key = "inbox.lastSeen"

    /// - Parameter defaults: where it's saved (tests pass their own suite).
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let saved = defaults.object(forKey: Self.key) as? Date {
            lastSeen = saved
        } else {
            // First launch: the last two days count as new, not a whole
            // month at once.
            lastSeen = Date.now.addingTimeInterval(-2 * 24 * 60 * 60)
            defaults.set(lastSeen, forKey: Self.key)
        }
    }

    /// Opening the Inbox: everything up to now has been seen.
    func markSeen(at date: Date = .now) {
        lastSeen = date
        defaults.set(date, forKey: Self.key)
    }
}
