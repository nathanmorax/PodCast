//
//  TranscriptViewModel.swift
//  Podcast
//
//  Created by Jonathan Mora on 04/06/26.
//


import Observation
import Speech

/// @MainActor: before, `generate` ran on a background executor after its first
/// `await`, so SwiftUI received state changes off the main thread.
@MainActor
@Observable
final class TranscriptViewModel {

    // MARK: - Estado observable
    var segments: [LocalTranscriptSegment] = []
    var isLoading: Bool = false
    var error: String?
    var progress: String = ""
    var currentSegment: LocalTranscriptSegment?
    /// Index of `currentSegment` in `segments` (for the previous/next lines).
    private(set) var currentIndex: Int?

    // MARK: - Private
    @ObservationIgnored private var currentEpisodeId: String?

    // MARK: - API pública

    func updateCurrentSegment(playbackSeconds: Double) {
        let index = segments.firstIndex {
            playbackSeconds >= $0.startTime && playbackSeconds <= $0.endTime
        }
        // Between two sentences there's a tiny gap: keep the last line instead
        // of blinking back to the title.
        guard let index, index != currentIndex else { return }
        currentIndex = index
        currentSegment = segments[index]
    }

    func loadIfCached(for episodeId: String) {
        currentEpisodeId = episodeId
        guard let segments = readCache(for: episodeId) else { return }
        self.segments = segments
    }

    func reset() {
        segments = []
        error = nil
        currentSegment = nil
        currentIndex = nil
    }

    @available(iOS 26.0, *)
    func generate(for streamUrl: String, episodeId: String, locale: Locale = Locale(identifier: "en-US")) async {
        guard let url = URL(string: streamUrl) else { return }
        guard !isLoading else { return }   // ignore repeated taps while it's working

        isLoading = true
        error = nil
        progress = String(localized: "Downloading audio…")
        currentEpisodeId = episodeId

        defer {
            isLoading = false
            progress = ""
        }

        do {
            let hasPermission = await requestSpeechPermission()
            guard hasPermission else {
                error = String(localized: "Speech recognition permission is needed")
                return
            }

            let localURL = try await AudioDownloader.shared.download(from: url)
            progress = String(localized: "Transcribing… (this can take a few minutes)")
            print("📥 ✅ Audio descargado en: \(localURL.path)")

            let result = try await LocalTranscriptionService.shared.transcribe(
                audioURL: localURL,
                locale: locale
            )

            writeCache(result, for: episodeId)
            segments = result

            try? FileManager.default.removeItem(at: localURL)

        } catch {
            self.error = error.localizedDescription
            print("Transcription error:", error)
        }
    }

    func clearCache() {
        guard let episodeId = currentEpisodeId else { return }
        try? FileManager.default.removeItem(at: cacheURL(for: episodeId))
        segments = []
    }

    // MARK: - Permisos

    private func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization {
                continuation.resume(returning: $0 == .authorized)
            }
        }
    }

    // MARK: - Cache

    private func readCache(for episodeId: String) -> [LocalTranscriptSegment]? {
        let url = cacheURL(for: episodeId)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([LocalTranscriptSegment].self, from: data)
    }

    private func writeCache(_ segments: [LocalTranscriptSegment], for episodeId: String) {
        guard let data = try? JSONEncoder().encode(segments) else { return }
        try? data.write(to: cacheURL(for: episodeId))
    }

    private func cacheURL(for episodeId: String) -> URL {
        let safeId = episodeId
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("transcript-\(safeId).json")
    }
}
