//
//  DownloadManagerTests.swift
//  PodcastTests
//

import Foundation
import Testing
@testable import Podcast

@MainActor
@Suite("DownloadManager")
struct DownloadManagerTests {

    // Fresh per test: isolated UserDefaults suite + temp folder + stubbed network.
    let defaults = UserDefaults.isolated()
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("DownloadManagerTests-\(UUID().uuidString)", isDirectory: true)

    private func makeSUT() -> DownloadManager {
        DownloadManager(userDefaults: defaults, session: .stubbed, downloadsDirectory: directory)
    }

    @Test("A new episode starts idle")
    func initialStateIsIdle() {
        let sut = makeSUT()
        #expect(sut.state(for: Fixtures.episode()) == .idle)
        #expect(sut.downloadedEpisodes.isEmpty)
    }

    @Test("A successful download moves the file and persists it across launches")
    func successfulDownload() async throws {
        let url = StubURLProtocol.register(.success(Data("audio".utf8)))
        let episode = Fixtures.episode(streamUrl: url.absoluteString)
        let sut = makeSUT()

        sut.download(episode)
        try await waitUntil { sut.state(for: episode).isDownloaded }

        let localURL = try #require(sut.localURL(for: episode))
        #expect(FileManager.default.fileExists(atPath: localURL.path))
        #expect(localURL.path.hasPrefix(directory.path))
        #expect(sut.downloadedEpisodes.map(\.streamUrl) == [episode.streamUrl])

        // Simulates the next app launch: a new manager restores the state.
        let relaunched = makeSUT()
        #expect(relaunched.localURL(for: episode) == localURL)
    }

    @Test("A failed download can be retried")
    func failedDownloadCanBeRetried() async throws {
        let url = StubURLProtocol.register(.failure(.notConnectedToInternet))
        let episode = Fixtures.episode(streamUrl: url.absoluteString)
        let sut = makeSUT()

        sut.download(episode)
        try await waitUntil { sut.state(for: episode).isFailed }

        StubURLProtocol.set(.success(Data("audio".utf8)), for: url)
        sut.download(episode)
        try await waitUntil { sut.state(for: episode).isDownloaded }
    }

    @Test("Cancelling goes back to idle and is not reported as a failure")
    func cancelResetsToIdle() async throws {
        let url = StubURLProtocol.register(.hang)
        let episode = Fixtures.episode(streamUrl: url.absoluteString)
        let sut = makeSUT()

        sut.download(episode)
        #expect(sut.state(for: episode).isDownloading)
        sut.cancelDownload(episode)
        #expect(sut.state(for: episode) == .idle)

        // URLSession reports the cancellation asynchronously as URLError.cancelled.
        // There is no hook to await "nothing happened", so give it a moment.
        try await Task.sleep(for: .milliseconds(300))
        #expect(sut.state(for: episode) == .idle)
    }

    @Test("Deleting a download removes the file from disk")
    func deleteRemovesFile() async throws {
        let url = StubURLProtocol.register(.success(Data("audio".utf8)))
        let episode = Fixtures.episode(streamUrl: url.absoluteString)
        let sut = makeSUT()

        sut.download(episode)
        try await waitUntil { sut.state(for: episode).isDownloaded }
        let localURL = try #require(sut.localURL(for: episode))

        sut.deleteDownload(episode)

        #expect(FileManager.default.fileExists(atPath: localURL.path) == false)
        #expect(sut.state(for: episode) == .idle)
        #expect(sut.downloadedEpisodes.isEmpty)
    }
}

private extension DownloadState {
    var isDownloaded: Bool { if case .downloaded = self { true } else { false } }
    var isDownloading: Bool { if case .downloading = self { true } else { false } }
    var isFailed: Bool { if case .failed = self { true } else { false } }
}
