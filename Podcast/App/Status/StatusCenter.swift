//
//  StatusCenter.swift
//  Podcast
//

import Foundation
import Observation

/// The app-wide state behind the status pill that isn't read straight from
/// a manager: whether feeds are refreshing, and short flashes ("Downloaded",
/// "Failed") that go away by themselves.
///
/// Anyone can report to it: `StatusCenter.shared.flash(.downloaded)`.
@MainActor
@Observable
final class StatusCenter {

    static let shared = StatusCenter()

    /// Followed feeds being read (Library sets it).
    var isUpdating = false

    /// A short message on top of everything else, for a moment.
    private(set) var flash: AppStatus?

    @ObservationIgnored private var flashTask: Task<Void, Never>?

    /// How long a flash stays.
    static let flashDuration: Duration = .seconds(2.5)

    func flash(_ status: AppStatus) {
        flashTask?.cancel()
        flash = status
        flashTask = Task { [weak self] in
            try? await Task.sleep(for: Self.flashDuration)
            guard !Task.isCancelled else { return }
            self?.flash = nil
        }
    }
}
