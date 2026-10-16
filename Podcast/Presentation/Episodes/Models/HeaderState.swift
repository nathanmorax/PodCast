//
//  HeaderState.swift
//  Podcast
//

import Foundation

// MARK: - HeaderState

struct HeaderState: Equatable {
    let isFavorite: Bool
    let description: String?
    let isLoadingDescription: Bool

    static func == (lhs: HeaderState, rhs: HeaderState) -> Bool {
        lhs.isFavorite == rhs.isFavorite &&
        lhs.isLoadingDescription == rhs.isLoadingDescription &&
        (lhs.description ?? "") == (rhs.description ?? "")
    }
}
