//
//  DownloadState.swift
//  Podcast
//

import Foundation

enum DownloadState: Equatable {
    case idle
    case waiting
    case downloading(progress: Double)
    case downloaded(localURL: URL)
    case failed(String)

    var iconName: String {
        switch self {
        case .idle:        return "arrow.down"
        case .waiting:     return "arrow.down"
        case .downloaded:  return "checkmark"
        case .downloading: return "circle.dashed"
        case .failed:      return "arrow.down"
        }
    }
}
