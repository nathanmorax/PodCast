//
//  OutlinePill.swift
//  Podcast
//

import SwiftUI

/// The editorial button: a capsule outline (no fill) with an icon and a
/// label, in one color: "🎧 Listen · 14 minutes". The accent for the main
/// action, the text color for the rest.
struct OutlinePill: View {

    let title: Text
    var systemImage: String?
    var color: Color = AppColor.Accent.strong
    var height: CGFloat = 46

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .contentTransition(.symbolEffect(.replace))
            }
            title
                .font(AppFont.button)
                .lineLimit(1)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 20)
        .frame(height: height)
        .overlay {
            Capsule().strokeBorder(color, lineWidth: 1.5)
        }
        .contentShape(Capsule())
    }
}

/// ▶ in an outlined circle: plays an episode from a list.
struct OutlinePlayButton: View {

    let isPlaying: Bool
    var color: Color = AppColor.Accent.strong
    var size: CGFloat = 40
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: size * 0.32, weight: .bold))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .overlay { Circle().strokeBorder(color, lineWidth: 1.5) }
                .frame(width: max(size, 44), height: max(size, 44))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? Text("Pause") : Text("Play"))
    }
}
