//
//  ListenCapsuleButton.swift
//  Podcast
//

import SwiftUI

/// 🎧 Listen · 30 min — an outlined capsule, like a magazine's "listen to
/// this story". Becomes ❚❚ Pause while this episode plays. Plays without
/// opening anything (the mini player shows it).
struct ListenCapsuleButton: View {

    let isPlaying: Bool
    /// "30 min"; empty hides the "· length" part.
    let duration: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isPlaying ? "pause.fill" : "headphones")
                    .font(.system(size: 16, weight: .regular))
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)
                Text(isPlaying ? "Pause" : "Listen")
                    .fontWeight(.semibold)
                if !duration.isEmpty, !isPlaying {
                    Text(verbatim: "·")
                        .accessibilityHidden(true)
                    Text(duration)
                }
            }
            .font(.callout)
            .foregroundStyle(AppColor.Accent.strong)
            .padding(.horizontal, 20)
            .frame(minHeight: 44)
            .overlay {
                Capsule().strokeBorder(AppColor.Text.primary.opacity(0.22), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isPlaying)
    }
}
