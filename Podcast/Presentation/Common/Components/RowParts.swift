//
//  RowParts.swift
//  Podcast
//

import SwiftUI

/// The pieces every list row shares (episodes and podcasts), like a
/// magazine's audio list: the show (or the category) in serif capitals in
/// the accent, the title in bold, a muted line, and the artwork on the
/// right, square, with ▶ on its corner when it plays.

/// "THE WRITER'S VOICE": serif capitals, spaced, in the accent.
struct RowOverline: View {

    let text: String

    var body: some View {
        Text(text.isEmpty ? " " : text)
            .font(.system(.subheadline, design: .serif))
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(AppColor.Accent.strong)
            .lineLimit(1)
    }
}

/// The row's title: bold sans, up to two lines.
struct RowTitle: View {

    let text: String

    var body: some View {
        Text(text)
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(AppColor.Text.primary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
}

/// Square artwork, slightly rounded, with a hairline edge (light covers
/// don't melt into the page).
struct RowArtwork<Content: View>: View {

    var side: CGFloat = 96
    @ViewBuilder let image: () -> Content

    static var cornerRadius: CGFloat { 6 }

    var body: some View {
        Color.clear
            .frame(width: side, height: side)
            .overlay { image() }
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                    .strokeBorder(AppColor.Text.primary.opacity(0.12), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}

/// ▶ black with a white ring, sitting on the artwork's bottom-right corner
/// (half out of it, like a sticker). Its own button: plays without opening.
struct RowPlayButton: View {

    let isPlaying: Bool
    let action: () -> Void

    static let size: CGFloat = 40

    var body: some View {
        Button(action: action) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 14, weight: .bold))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(.white)
                .frame(width: Self.size, height: Self.size)
                .background(Circle().fill(.black))
                .overlay { Circle().strokeBorder(.white, lineWidth: 1.5) }
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? Text("Pause") : Text("Play"))
    }
}
