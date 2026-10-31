//
//  AppStatusResolverTests.swift
//  PodcastTests
//

import Testing
import Foundation
@testable import Podcast

/// Which word the status pill shows when several things happen at once.
@Suite("AppStatusResolver")
struct AppStatusResolverTests {

    @Test("Nothing going on: no pill")
    func idle() {
        #expect(AppStatusResolver.resolve(isOffline: false, downloads: [], isUpdating: false, flash: nil) == nil)
    }

    @Test("Offline wins over everything")
    func offlineFirst() {
        let status = AppStatusResolver.resolve(isOffline: true, downloads: [0.5], isUpdating: true, flash: .downloaded)
        #expect(status == .offline)
    }

    @Test("Downloads: average progress and how many")
    func downloading() {
        let status = AppStatusResolver.resolve(isOffline: false, downloads: [0.2, 0.6], isUpdating: true, flash: nil)
        #expect(status == .downloading(progress: 0.4, count: 2))
    }

    @Test("A failure shows over downloads in progress; a success waits for them")
    func flashes() {
        #expect(AppStatusResolver.resolve(isOffline: false, downloads: [0.5], isUpdating: false, flash: .failed) == .failed)
        #expect(AppStatusResolver.resolve(isOffline: false, downloads: [0.5], isUpdating: false, flash: .downloaded)
                == .downloading(progress: 0.5, count: 1))
        #expect(AppStatusResolver.resolve(isOffline: false, downloads: [], isUpdating: true, flash: .downloaded) == .downloaded)
    }

    @Test("Updating only when nothing else")
    func updating() {
        #expect(AppStatusResolver.resolve(isOffline: false, downloads: [], isUpdating: true, flash: nil) == .updating)
    }

    @Test("Waiting downloads count as 0; finished and failed ones don't count")
    func progressOfStates() {
        let states: [DownloadState] = [.waiting, .downloading(progress: 0.5),
                                       .downloaded(localURL: URL(fileURLWithPath: "/x")), .failed("e"), .idle]
        #expect(AppStatusResolver.downloadProgress(states) == [0, 0.5])
    }

    @Test("What you just did shows right away, even over downloads; offline still wins")
    func confirmations() {
        for flash in [AppStatus.saved, .unsaved, .followed, .unfollowed, .downloadRemoved, .downloadCanceled, .removedFromHistory] {
            #expect(AppStatusResolver.resolve(isOffline: false, downloads: [0.5], isUpdating: true, flash: flash) == flash)
            #expect(AppStatusResolver.resolve(isOffline: true, downloads: [], isUpdating: false, flash: flash) == .offline)
        }
    }
}
