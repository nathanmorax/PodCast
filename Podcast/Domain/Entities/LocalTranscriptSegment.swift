//
//  LocalTranscriptSegment.swift
//  Podcast
//

import Foundation

/// Segmento de transcripción con timestamps
struct LocalTranscriptSegment: Identifiable, Codable {
    let id = UUID()
    let text: String
    let startTime: Double
    let endTime: Double
}
