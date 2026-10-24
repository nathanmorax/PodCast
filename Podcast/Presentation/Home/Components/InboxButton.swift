//
//  InboxButton.swift
//  Podcast
//

import SwiftUI

/// The tray at the top right of Library: opens the Inbox. Full, with a
/// mustard badge, when the podcasts you follow have new episodes.
struct InboxButton: View {

    let newCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: newCount > 0 ? "tray.full" : "tray")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AppColor.Text.primary)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: newCount)
                .frame(width: 44, height: 44)
                .overlay(alignment: .topTrailing) {
                    if newCount > 0 { badge }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Inbox")
        .accessibilityValue(newCount > 0 ? Text("\(newCount) new") : Text(verbatim: ""))
    }

    private var badge: some View {
        Text(verbatim: newCount > 99 ? "99+" : "\(newCount)")
            .font(.system(size: 11, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(AppColor.Text.onPastel)
            .padding(.horizontal, 5)
            .frame(minWidth: 18, minHeight: 18)
            .background(Capsule().fill(AppColor.Accent.soft))
            .offset(x: -1, y: 3)
            .transition(.scale.combined(with: .opacity))
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HStack {
        InboxButton(newCount: 0) {}
        InboxButton(newCount: 3) {}
        InboxButton(newCount: 120) {}
    }
    .padding()
}
