//
//  LibraryGroups.swift
//  Podcast
//

import Foundation

/// One show in the Library and its episodes, in the tab's order.
struct LibraryShowGroup: Identifiable, Equatable {
    let showName: String
    /// The show's cover (taken from its first episode).
    let artwork: String?
    let items: [LibraryItem]

    var id: String { showName }
}

/// The Library groups each tab's episodes by show. Pure, so it's tested.
enum LibraryGroups {

    /// Shows in the order their first episode appears (the tab already
    /// sorts newest first, so the show with the latest one leads); each
    /// show keeps its episodes in that same order.
    static func group(_ items: [LibraryItem]) -> [LibraryShowGroup] {
        var order: [String] = []
        var byShow: [String: [LibraryItem]] = [:]
        for item in items {
            if byShow[item.showName] == nil { order.append(item.showName) }
            byShow[item.showName, default: []].append(item)
        }
        return order.compactMap { name in
            guard let items = byShow[name], let first = items.first else { return nil }
            return LibraryShowGroup(showName: name, artwork: first.showArtwork, items: items)
        }
    }
}
