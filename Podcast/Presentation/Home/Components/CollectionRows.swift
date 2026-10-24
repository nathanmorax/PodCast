//
//  CollectionRows.swift
//  Podcast
//

import SwiftUI

/// Following · Favorites · Downloads in Library, as three rows: a small
/// green icon, the name in serif, how many there are, and ›.
/// The icons are the ones the app already uses for each action.
struct CollectionRows: View {

    let following: Int
    let favorites: Int
    let downloads: Int
    let onOpenFollowing: () -> Void
    let onOpenFavorites: () -> Void
    let onOpenDownloads: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            // Each row is what its list zooms out of and back into.
            ZoomSourceHost(id: .collection(.following)) {
                CollectionRow(title: "Following", systemImage: "square.stack", count: following, action: onOpenFollowing)
            }
            Divider()
            ZoomSourceHost(id: .collection(.favorites)) {
                CollectionRow(title: "Favorites", systemImage: "bookmark", count: favorites, action: onOpenFavorites)
            }
            Divider()
            ZoomSourceHost(id: .collection(.downloads)) {
                CollectionRow(title: "Downloads", systemImage: "arrow.down.circle", count: downloads, action: onOpenDownloads)
            }
            Divider()
        }
    }
}

private struct CollectionRow: View {

    let title: LocalizedStringKey
    let systemImage: String
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColor.Accent.strong)
                    .frame(width: 22)
                    .accessibilityHidden(true)
                Text(title)
                    .font(AppFont.itemTitle)
                    .foregroundStyle(AppColor.Text.primary)
                Spacer(minLength: 8)
                if count > 0 {
                    Text(count, format: .number)
                        .font(AppFont.footnote)
                        .monospacedDigit()
                        .foregroundStyle(AppColor.Text.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.Text.tertiary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    CollectionRows(following: 12, favorites: 4, downloads: 0,
                   onOpenFollowing: {}, onOpenFavorites: {}, onOpenDownloads: {})
        .padding()
}
