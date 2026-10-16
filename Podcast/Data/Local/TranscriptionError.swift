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
        case .localeNotSupported: return String(localized: "Language not supported by SpeechAnalyzer")
        case .modelNotInstalled: return String(localized: "Couldn't download the model")
        case .audioFileLoadFailed: return String(localized: "Couldn't load the audio")
        case .transcriptionFailed: return String(localized: "Transcription failed")
        }
    }
}
