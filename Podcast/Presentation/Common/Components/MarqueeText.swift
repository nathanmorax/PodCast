//
//  MarqueeText.swift
//  Podcast
//

import SwiftUI

/// One line of text that, when it doesn't fit, slides sideways to show the
/// rest (a pause at the start of each lap), its edges fading out instead of
/// being cut. When it fits, or with Reduce Motion on, it's a plain line
/// that ends in "…". VoiceOver reads the whole text once.
struct MarqueeText: View {

    let text: String
    var font: Font = .body
    /// Points per second.
    var speed: CGFloat = 32
    /// Space between the end of the text and its next lap.
    var gap: CGFloat = 36
    /// How wide the fade at each edge is.
    var fade: CGFloat = 14
    /// How long it rests at the start of each lap.
    var pause: TimeInterval = 2

    @State private var textWidth: CGFloat = 0
    @State private var boxWidth: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var scrolls: Bool { !reduceMotion && textWidth > boxWidth + 1 && boxWidth > 0 }

    var body: some View {
        // The plain line sets the height and the width available; it's
        // also what shows when nothing needs to move.
        Text(text)
            .font(font)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(scrolls ? 0 : 1)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { boxWidth = $0 }
            .background(alignment: .leading) {
                Text(text)
                    .font(font)
                    .lineLimit(1)
                    .fixedSize()
                    .hidden()
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { textWidth = $0 }
            }
            .overlay(alignment: .leading) {
                if scrolls { moving }
            }
            .clipped()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: text))
    }

    /// The text twice in a row, slid left one lap at a time.
    private var moving: some View {
        let lap = textWidth + gap
        let duration = TimeInterval(lap / speed)
        return TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: duration + pause)
            let x = time < pause ? 0 : -CGFloat((time - pause) / duration) * lap
            HStack(spacing: gap) {
                line
                line
            }
            .offset(x: x)
        }
        .mask {
            HStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                    .frame(width: fade)
                Rectangle()
                LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: fade)
            }
        }
    }

    private var line: some View {
        Text(text)
            .font(font)
            .lineLimit(1)
            .fixedSize()
    }
}
