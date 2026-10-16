//
//  TranscriptSubtitleView.swift
//  Podcast
//

import SwiftUI

/// The transcript as subtitles: one sentence, big and centered, with the one
/// before it faint above. A single pill at the bottom pauses/plays and shows
/// the time. Nothing else on screen.
///
/// Colors are made for reading: Noche (warm near-black + cream) or Papel
/// (sepia + warm ink), never pure black/white. The app is light-only, so the
/// listener picks the theme here and it's remembered.
struct TranscriptSubtitleView: View {

    let previous: String?
    let current: String?
    /// Changes when the sentence changes, to animate the swap.
    let lineID: UUID?
    let isPlaying: Bool
    let timeText: String
    let onTogglePlay: () -> Void
    let onClose: () -> Void

    @AppStorage("transcriptReadingTheme") private var theme: ReadingTheme = .night

    var body: some View {
        ZStack {
            AppColor.readingBackground
                .ignoresSafeArea()

            // The id swap + transition roll the old sentence out and the new
            // one in; the animation lives on the container so both run.
            ZStack {
                sentences
                    .id(lineID)
                    .transition(.subtitleLine)
            }
            .padding(.horizontal, 32)
            .animation(AppAnimation.subtitleLine, value: lineID)

            VStack {
                topBar
                Spacer()
                playPill
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 18)
        }
        .foregroundStyle(AppColor.readingText)
        // Resolves the reading colors' light/dark variants for this screen only.
        .environment(\.colorScheme, theme.colorScheme)
        .animation(AppAnimation.readingTheme, value: theme)
        .statusBarHidden()
        .gesture(swipeDownToClose)
    }

    // MARK: - Sentences

    private var sentences: some View {
        VStack(spacing: 22) {
            if let previous {
                Text(previous)
                    .font(.system(.body, weight: .medium))
                    .lineSpacing(3)
                    .opacity(0.32)
                    .accessibilityHidden(true)
            }
            if let current {
                Text(current)
                    .font(.system(.title, weight: .semibold))
                    .tracking(-0.4)
                    .lineSpacing(2)
                    .minimumScaleFactor(0.6)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack {
            Button {
                theme = theme.toggled
            } label: {
                Image(systemName: theme == .night ? "sun.max" : "moon")
                    .font(.system(size: 17, weight: .medium))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(theme == .night ? Text("Light reading mode") : Text("Dark reading mode"))

            Spacer()

            Button(action: onClose) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Back to the player")
        }
        .buttonStyle(.plain)
        .opacity(0.45)
        .padding(.top, 8)
    }

    private var playPill: some View {
        Button(action: onTogglePlay) {
            HStack(spacing: 10) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                Text(timeText)
                    .font(.system(size: 15, weight: .semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .foregroundStyle(AppColor.readingBackground)
            .padding(.leading, 16)
            .padding(.trailing, 20)
            .frame(height: 48)
            .background(AppColor.readingText, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? Text("Pause") : Text("Play"))
        .accessibilityValue(timeText)
    }

    /// Swiping down goes back to the player (the chevron does the same).
    private var swipeDownToClose: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let isVertical = abs(value.translation.height) > abs(value.translation.width)
                if isVertical, value.translation.height > 100 { onClose() }
            }
    }
}

// MARK: - Theme

enum ReadingTheme: String {
    case night
    case paper

    var colorScheme: ColorScheme { self == .night ? .dark : .light }
    var toggled: ReadingTheme { self == .night ? .paper : .night }
}

#Preview("Noche") {
    TranscriptSubtitleView(
        previous: "Posponemos porque la tarea nos hace sentir algo incómodo.",
        current: "El cerebro busca alivio inmediato, y lo encuentra en cualquier otra cosa.",
        lineID: UUID(), isPlaying: true, timeText: "12:04 / 32:00",
        onTogglePlay: {}, onClose: {}
    )
}
