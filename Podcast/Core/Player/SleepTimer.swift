//
//  SleepTimer.swift
//  Podcast
//

import Foundation
import Observation

/// The player's ☾: pauses after a while, or when the episode ends. One for
/// the app; starting a new one replaces the old.
@MainActor
@Observable
final class SleepTimer {

    static let shared = SleepTimer()

    enum Option: Hashable {
        case minutes(Int)
        case endOfEpisode
    }

    /// The choices in its menu, besides "End of episode".
    static let minuteOptions = [5, 15, 30, 45, 60]

    /// When it pauses; nil = off.
    private(set) var endsAt: Date?
    private(set) var option: Option?

    var isActive: Bool { endsAt != nil }

    @ObservationIgnored private var task: Task<Void, Never>?

    /// - Parameters:
    ///   - remaining: seconds of the episode left (for End of episode).
    ///   - rate: the playback speed (a faster episode ends sooner).
    ///   - onFire: what to do when it runs out (pause).
    func start(_ option: Option, remaining: Double, rate: Float, onFire: @escaping @MainActor () -> Void) {
        cancel()
        let seconds = Self.seconds(for: option, remaining: remaining, rate: rate)
        guard seconds > 0 else { return }
        self.option = option
        endsAt = Date().addingTimeInterval(seconds)
        task = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            onFire()
            self?.cancel()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        endsAt = nil
        option = nil
    }

    /// How long until it pauses. Pure, so it's tested.
    nonisolated static func seconds(for option: Option, remaining: Double, rate: Float) -> Double {
        switch option {
        case .minutes(let minutes):
            return Double(minutes * 60)
        case .endOfEpisode:
            return max(remaining, 0) / Double(max(rate, 0.1))
        }
    }
}
