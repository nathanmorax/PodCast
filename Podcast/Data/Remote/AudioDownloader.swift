//
//  AudioDownloader.swift
//  Podcast
//

import Foundation

/// Sendable: stateless; safe to call from any isolation.
final class AudioDownloader: Sendable {
    
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
