//
//  LocalTranscriptSegment.swift
//  Podcast
//

import Foundation

/// One line of a transcript, with its timestamps.
struct LocalTranscriptSegment: Identifiable, Codable, Sendable {
    /// Only for SwiftUI lists: a new one on every launch, never saved.
    let id = UUID()
    let text: String
    let startTime: Double
    let endTime: Double

    /// `id` is left out on purpose (same behavior as before, without the
    /// "immutable property will not be decoded" warning).
    private enum CodingKeys: String, CodingKey {
        case text, startTime, endTime
    }
}
