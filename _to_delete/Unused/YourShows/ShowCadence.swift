//
//  ShowCadence.swift
//  Podcast
//

import Foundation

/// How often a show publishes ("Every week"), read from its episodes'
/// dates: the median gap between the latest ones. Pure, so it's tested.
enum ShowCadence: Equatable {
    case daily
    case weekly
    case biweekly
    case monthly

    /// How many recent gaps it looks at.
    static let sample = 8

    /// Nil when there are fewer than three episodes or no clear rhythm
    /// (more than ~6 weeks between them).
    init?(dates: [Date]) {
        let sorted = dates.sorted(by: >).prefix(Self.sample + 1)
        guard sorted.count >= 3 else { return nil }
        let gaps = zip(sorted, sorted.dropFirst())
            .map { $0.timeIntervalSince($1) / 86_400 }
            .sorted()
        let median = gaps[gaps.count / 2]
        switch median {
        case ..<2.5: self = .daily
        case ..<10: self = .weekly
        case ..<20: self = .biweekly
        case ..<45: self = .monthly
        default: return nil
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .daily: "Daily"
        case .weekly: "Every week"
        case .biweekly: "Every two weeks"
        case .monthly: "Every month"
        }
    }
}
