//
//  NetworkMonitor.swift
//  Podcast
//

import Foundation
import Network
import Observation

/// Whether the phone can reach the internet right now (NWPathMonitor),
/// observable from SwiftUI. The status pill shows "Offline" from it.
@MainActor
@Observable
final class NetworkMonitor {

    static let shared = NetworkMonitor()

    private(set) var isOffline = false

    @ObservationIgnored private let monitor = NWPathMonitor()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let offline = path.status != .satisfied
            Task { @MainActor in
                guard let self, self.isOffline != offline else { return }
                self.isOffline = offline
            }
        }
        // Runs for the app's whole life (a single shared instance).
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }
}
