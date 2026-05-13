//
//  LocalTranscriptionService.swift
//  Podcast
//
//  Created by Satori Tech 341 on 13/05/26.
//


import Foundation
import Speech
import AVFoundation

enum TranscriptionError: LocalizedError {
    case localeNotSupported
    case modelNotInstalled
    case audioFileLoadFailed
    case transcriptionFailed
    
    var errorDescription: String? {
        switch self {
        case .localeNotSupported: return "Idioma no soportado por SpeechAnalyzer"
        case .modelNotInstalled: return "Modelo no se pudo descargar"
        case .audioFileLoadFailed: return "No se pudo cargar el audio"
        case .transcriptionFailed: return "Falló la transcripción"
        }
    }
}

/// Segmento de transcripción con timestamps
struct LocalTranscriptSegment: Identifiable, Codable {
    let id = UUID()
    let text: String
    let startTime: Double
    let endTime: Double
}

@available(iOS 26.0, *)
final class LocalTranscriptionService {
    
    static let shared = LocalTranscriptionService()
    private init() {}
    
    /// Transcribe un archivo de audio local y devuelve segmentos con timestamps
    @available(iOS 26.0, *)
    func transcribe(
        audioURL: URL,
        locale: Locale = Locale(identifier: "en-US")
    ) async throws -> [LocalTranscriptSegment] {
        
        print("🎤 [1] Iniciando transcripción para: \(audioURL.lastPathComponent)")
        print("🎤 [2] Locale solicitado: \(locale.identifier)")
        
        // ============================================
        // 🔍 DEBUG: Lista todos los locales disponibles
        // ============================================
        let supported = await SpeechTranscriber.supportedLocales
        print("📋 ============================================")
        print("📋 Locales SOPORTADOS (\(supported.count)):")
        for loc in supported {
            print("   ✓ \(loc.identifier) → bcp47: \(loc.identifier(.bcp47))")
        }
        print("📋 ============================================")
        
        let installed = await SpeechTranscriber.installedLocales
        print("📋 Locales INSTALADOS (\(installed.count)):")
        for loc in installed {
            print("   📦 \(loc.identifier) → bcp47: \(loc.identifier(.bcp47))")
        }
        print("📋 ============================================")
        // ============================================
        
        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: [.audioTimeRange]
        )
        
        print("🎤 [3] Verificando modelo...")
        try await ensureModelInstalled(for: transcriber, locale: locale)
        print("🎤 [4] Modelo listo")
        
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        
        let audioFile = try AVAudioFile(forReading: audioURL)
        print("🎤 [5] Audio cargado. Duración: \(audioFile.length) samples")
        
        async let segmentsFuture: [LocalTranscriptSegment] = collectSegments(from: transcriber)
        
        print("🎤 [6] Analizando audio...")
        if let lastSample = try await analyzer.analyzeSequence(from: audioFile) {
            print("🎤 [7] Finalizando en sample: \(lastSample)")
            try await analyzer.finalizeAndFinish(through: lastSample)
        }
        
        let segments = try await segmentsFuture
        print("🎤 [8] ✅ Transcripción completa: \(segments.count) segmentos")
        
        return segments
    }

    private func collectSegments(
        from transcriber: SpeechTranscriber
    ) async throws -> [LocalTranscriptSegment] {
        
        var segments: [LocalTranscriptSegment] = []
        var counter = 0
        
        for try await result in transcriber.results {
            counter += 1
            
            if result.isFinal {
                let text = String(result.text.characters)
                let range = result.range
                print("🎤 ✅ Segmento \(segments.count + 1): [\(String(format: "%.1f", range.start.seconds))s-\(String(format: "%.1f", range.end.seconds))s] '\(text)'")
                
                segments.append(LocalTranscriptSegment(
                    text: text,
                    startTime: range.start.seconds,
                    endTime: range.end.seconds
                ))
            } else {
                print("🎤 ⏳ Resultado parcial #\(counter)")
            }
        }
        
        return segments
    }
    
    // MARK: Verifica e instala el modelo del idioma si hace falta -
    private func ensureModelInstalled(
        for transcriber: SpeechTranscriber,
        locale: Locale
    ) async throws {
        
        let supportedLocales = await SpeechTranscriber.supportedLocales
        let isSupported = supportedLocales
            .map { $0.identifier(.bcp47) }
            .contains(locale.identifier(.bcp47))
        
        guard isSupported else {
            throw TranscriptionError.localeNotSupported
        }
        
        let installedLocales = await Set(SpeechTranscriber.installedLocales)
        let isInstalled = installedLocales
            .map { $0.identifier(.bcp47) }
            .contains(locale.identifier(.bcp47))
        
        if isInstalled {
            return
        }
        
        if let downloader = try await AssetInventory.assetInstallationRequest(
            supporting: [transcriber]
        ) {
            try await downloader.downloadAndInstall()
        }
    }
}

import Foundation

final class AudioDownloader {
    
    static let shared = AudioDownloader()
    private init() {}
    
    func download(from url: URL) async throws -> URL {
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")
        
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }
}
