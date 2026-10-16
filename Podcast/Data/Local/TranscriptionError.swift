//
//  TranscriptionError.swift
//  Podcast
//

import Foundation

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
