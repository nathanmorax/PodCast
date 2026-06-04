//
//  PlayerDetailViewModel.swift
//  Podcast
//
//  Created by Jesus Mora on 30/01/26.
//

import AVKit
import Observation
import Speech

@Observable
class AVPlayerViewModel {
    
    // MARK: - Playback state (observable)
    
    var isPlaying: Bool = false
    var currentTimeText: String = "00:00"
    var durationText: String = "00:00"
    var progress: Float = 0
    
    // MARK: - Transcript state (observable)
    
    var transcriptSegments: [LocalTranscriptSegment] = []
    var isLoadingTranscript: Bool = false
    var transcriptError: String?
    var transcriptProgress: String = ""
    
    /// Segmento activo según el tiempo actual de reproducción
    var currentSegment: LocalTranscriptSegment? {
        let currentSeconds = currentPlaybackSeconds
        return transcriptSegments.first { segment in
            currentSeconds >= segment.startTime && currentSeconds <= segment.endTime
        }
    }
    
    // MARK: - Private (no observable)
    
    @ObservationIgnored
    private let bookmarkManager: BookMarkEpisodeManager
    
    @ObservationIgnored
    private let player: AVPlayerDataSource
    
    @ObservationIgnored
    private var currentURL: URL?
    
    @ObservationIgnored
    private var currentEpisodeId: String?
    
    @ObservationIgnored
    private var currentDurationSeconds: Double = 0
    
    /// Tiempo actual en segundos (Double, para comparar con startTime/endTime)
    @ObservationIgnored
    private var currentPlaybackSeconds: Double {
        Double(progress) * currentDurationSeconds
    }
    
    // MARK: - Init
    
    init(player: AVPlayerDataSource = AVPlayerDataSource(), bookmarkManager: BookMarkEpisodeManager = .shared) {
        self.player = player
        self.bookmarkManager = bookmarkManager
        self.bind()
        self.configureAudioSession()
    }
    
    // MARK: - Audio session
    
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Audio session error:", error)
        }
    }
    
    // MARK: - Player bindings
    
    private func bind() {
        player.onTimeUpdate = { [weak self] current, duration in
            guard let self else { return }
            
            self.currentTimeText = current.toDisplayString()
            self.durationText = duration?.toDisplayString() ?? ""
            
            let totalSeconds = CMTimeGetSeconds(duration ?? CMTime(value: 1, timescale: 1))
            let currentSeconds = CMTimeGetSeconds(current)
            
            guard totalSeconds.isFinite, totalSeconds > 0,
                  currentSeconds.isFinite else { return }
            
            self.currentDurationSeconds = totalSeconds
            self.progress = Float(currentSeconds / totalSeconds)
        }
        
        player.onStateChange = { [weak self] isPlaying in
            self?.isPlaying = isPlaying
        }
        
        player.onEpisodeStarted = { [weak self] in
            _ = self
        }
    }
    
    // MARK: - Playback API
    
    func playEpisode(_ episode: Episode) {
        guard let url = URL(string: episode.streamUrl) else { return }
        currentURL = url
        currentEpisodeId = episode.streamUrl
        player.play(url: url)
        
        // Reset transcript al cambiar de episodio
        transcriptSegments = []
        transcriptError = nil
        
        // Intenta cargar desde caché automáticamente
        loadCachedTranscriptIfAvailable(for: episode.streamUrl)
    }
    
    func togglePlayPause() {
        guard currentURL != nil else { return }
        isPlaying ? player.pause() : player.resume()
    }
    
    func seekForward() {
        player.seek(by: 15)
    }
    
    func seekBackward() {
        player.seek(by: -15)
    }
    
    func seek(to percentage: Float) {
        player.seek(to: percentage)
    }
    
    func setVolume(_ value: Float) {
        player.setVolume(value)
    }
    
    func toggleBookmark(for episode: Episode) {
        bookmarkManager.toggle(episode)
    }
    
    func isBookMarked(_ episode: Episode) -> Bool {
        bookmarkManager.isBookMarked(episode)
    }
    
    // MARK: - Transcript API
    
    /// Genera el transcript del episodio actual usando SpeechAnalyzer local
    @available(iOS 26.0, *)
    func generateTranscript(
        for streamUrl: String,
        episodeId: String,
        locale: Locale = Locale(identifier: "en-US")
    ) async {
        
        print("📥 Descargando audio desde: \(streamUrl)")

        guard let url = URL(string: streamUrl) else { return }
        
        isLoadingTranscript = true
        transcriptError = nil
        transcriptProgress = "Descargando audio..."
        
        defer {
            isLoadingTranscript = false
            transcriptProgress = ""
        }
        
        do {
            // Verifica permisos primero
            let hasPermission = await requestSpeechPermission()
            guard hasPermission else {
                transcriptError = "Se necesita permiso de reconocimiento de voz"
                return
            }
            
            // 1. Descarga el MP3
            let localURL = try await AudioDownloader.shared.download(from: url)
            
            transcriptProgress = "Transcribiendo... (puede tardar varios minutos)"
            print("📥 ✅ Audio descargado en: \(localURL.path)")
            print("📥 Tamaño: \(try? FileManager.default.attributesOfItem(atPath: localURL.path)[.size] ?? 0) bytes")
            
            // 2. Transcribe localmente
            let segments = try await LocalTranscriptionService.shared.transcribe(
                audioURL: localURL,
                locale: locale
            )
            
            // 3. Guarda en caché
            cacheTranscript(segments, for: episodeId)
            
            transcriptSegments = segments
            
            // 4. Limpia el archivo temporal
            try? FileManager.default.removeItem(at: localURL)
            
        } catch {
            transcriptError = error.localizedDescription
            print("Transcription error:", error)
        }
    }
    
    /// Borra el transcript en caché del episodio actual
    func clearTranscriptCache() {
        guard let episodeId = currentEpisodeId else { return }
        let url = transcriptCacheURL(for: episodeId)
        try? FileManager.default.removeItem(at: url)
        transcriptSegments = []
    }
    
    // MARK: - Permission
    
    private func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    // MARK: - Cache helpers
    
    private func loadCachedTranscriptIfAvailable(for episodeId: String) {
        let url = transcriptCacheURL(for: episodeId)
        guard let data = try? Data(contentsOf: url),
              let segments = try? JSONDecoder().decode([LocalTranscriptSegment].self, from: data) else {
            return
        }
        transcriptSegments = segments
    }
    
    private func cacheTranscript(_ segments: [LocalTranscriptSegment], for episodeId: String) {
        guard let data = try? JSONEncoder().encode(segments) else { return }
        let url = transcriptCacheURL(for: episodeId)
        try? data.write(to: url)
    }
    
    private func transcriptCacheURL(for episodeId: String) -> URL {
        let cacheDir = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0]
        
        // Sanitiza el ID para usarlo como nombre de archivo
        let safeId = episodeId
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        
        return cacheDir.appendingPathComponent("transcript-\(safeId).json")
    }
}

