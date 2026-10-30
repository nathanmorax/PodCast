//
//  LibraryShowSection.swift
//  Podcast
//

import SwiftUI

/// One show in the Library: its colored band, then its episodes as lines
/// or as a grid of covers (two or three across), by the chosen layout.
struct LibraryShowSection: View {

    let group: LibraryShowGroup
    let layout: LibraryLayout
    let badge: Text
    let onOpen: (LibraryItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            LibraryShowHeader(name: group.showName, artwork: group.artwork, badge: badge)

            if let columns = layout.columns {
                grid(columns: columns)
            } else {
                list
            }
        }
        .background(AppColor.paper)
    }

    private var list: some View {
        VStack(spacing: 0) {
            ForEach(group.items) { item in
                if item.id != group.items.first?.id {
                    Divider()
                }
                LibraryEpisodeLine(item: item) { onOpen(item) }
            }
        }
        .padding(.horizontal, 20)
    }

    private func grid(columns: Int) -> some View {
        let gap: CGFloat = columns > 2 ? 8 : 12
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: gap, alignment: .top), count: columns),
            alignment: .leading,
            spacing: 16
        ) {
            ForEach(group.items) { item in
                LibraryEpisodeTile(item: item, isCompact: columns > 2) { onOpen(item) }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }
}
