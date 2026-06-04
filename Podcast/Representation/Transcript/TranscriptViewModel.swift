//
//  TranscriptViewModel.swift
//  Podcast
//
//  Created by Jonathan Mora on 04/06/26.
//


import Observation
import Speech

@Observable
final class TranscriptViewModel {

    // MARK: - Estado observable
    var segments: [LocalTranscriptSegment] = []
    var isLoading: Bool = false
    var error: String?
    var progress: String = ""
    var currentSegment: LocalTranscriptSegment?

    // MARK: - Private
    @ObservationIgnored private var currentEpisodeId: String?

    // MARK: - API pública

    func updateCurrentSegment(playbackSeconds: Double) {
        currentSegment = segments.first {
            playbackSeconds >= $0.startTime && playbackSeconds <= $0.endTime
        }
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
    }

    @available(iOS 26.0, *)
    func generate(for streamUrl: String, episodeId: String, locale: Locale = Locale(identifier: "en-US")) async {
        guard let url = URL(string: streamUrl) else { return }

        isLoading = true
        error = nil
        progress = "Descargando audio..."
        currentEpisodeId = episodeId

        defer {
            isLoading = false
            progress = ""
        }

        do {
            let hasPermission = await requestSpeechPermission()
            guard hasPermission else {
                error = "Se necesita permiso de reconocimiento de voz"
                return
            }

            let localURL = try await AudioDownloader.shared.download(from: url)
            progress = "Transcribiendo... (puede tardar varios minutos)"
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
