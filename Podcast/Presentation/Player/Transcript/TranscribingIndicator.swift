//
//  TranscribingIndicator.swift
//  Podcast
//

import SwiftUI

/// Shown while the transcript is being made on the iPhone (it can take
/// minutes). Instead of technical steps ("Downloading…"), a waveform that
/// keeps moving and a short phrase that changes every few seconds, so it's
/// clear something is happening and that waiting is normal.
struct TranscribingIndicator: View {

    /// Rotates in order; the last ones encourage waiting.
    static let phrases: [LocalizedStringResource] = [
        "Listening to the episode…",
        "Turning voices into text…",
        "This can take a few minutes.",
        "Keep listening, it'll show up here.",
        "Still working, it's worth the wait.",
    ]

    /// Seconds each phrase stays on screen.
    static let phraseDuration: Duration = .seconds(3.5)

    @State private var index = 0

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "waveform")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(AppColor.accentInk)
                .symbolEffect(.variableColor.iterative.reversing, options: .repeating)
                .accessibilityHidden(true)

            Text(Self.phrases[index])
                .font(AppFont.button)
                .foregroundStyle(AppColor.ink)
                .multilineTextAlignment(.center)
                .id(index)
                .transition(.subtitleLine)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(AppAnimation.subtitleLine, value: index)
        .task {
            // Ends by itself when the view goes away (transcript ready).
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.phraseDuration)
                guard !Task.isCancelled else { return }
                index = (index + 1) % Self.phrases.count
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview {
    TranscribingIndicator()
}
