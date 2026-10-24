//
//  FollowButton.swift
//  Podcast
//

import SwiftUI

/// The small round + / ✓ next to a podcast in Search: follows it right there,
/// without opening it.
struct FollowButton: View {

    let podcast: Podcast
    @Environment(\.favoritesManager) private var favorites

    private var isFollowing: Bool {
        favorites.isFavorite(podcast)
    }

    var body: some View {
        Button {
            withAnimation(AppAnimation.listChange) {
                favorites.toggleFavorite(podcast)
            }
        } label: {
            Image(systemName: isFollowing ? "checkmark" : "plus")
                .font(.system(size: 13, weight: .bold))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(isFollowing ? AppColor.Text.inverse : AppColor.Accent.strong)
                .frame(width: 32, height: 32)
                .background(isFollowing ? AppColor.Accent.strong : AppColor.Accent.wash, in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isFollowing)
        .accessibilityLabel(isFollowing ? Text("Unfollow") : Text("Follow"))
    }
}
