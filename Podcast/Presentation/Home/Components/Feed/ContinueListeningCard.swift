//
//  ContinueListeningCard.swift
//  Podcast
//

import SwiftUI

/// The mustard card in Home's feed (like a magazine's highlighted review):
/// the last episode you started and didn't finish, its title in tall
/// capitals, "23 min left", ▶ and how far you got as a bar. The one in the
/// player follows it live.
///
/// The texts open its details; ▶ resumes (or pauses) it. Holding it offers
/// Remove.
struct ContinueListeningCard: View {

    let item: RecentlyPlayed
    let onResume: () -> Void
    let onOpen: () -> Void
    let onRemove: () -> Void

    // A ZoomSourceHost doesn't pass custom environment values on: the
    // shared player is read directly.
    private var playerManager: PlayerManager { .shared }

    private var isCurrent: Bool {
        playerManager.currentEpisode?.streamUrl == item.episode.streamUrl
    }

    private var isPlaying: Bool {
        isCurrent && playerManager.viewModel.isPlaying
    }

    /// Live for the episode in the player; as saved for the others.
    private var progress: Double {
        isCurrent ? Double(playerManager.viewModel.progress) : item.progress
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Continue listening")
                        .font(.caption.weight(.bold))
                    Text(item.episode.title)
                        .font(AppFont.feedTitle)
                        .textCase(.uppercase)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 4) {
                        Text(item.episode.author)
                            .fontWeight(.bold)
                            .textCase(.uppercase)
                            .lineLimit(1)
                        Text(verbatim: "·")
                        Text("\(item.minutesLeftText(at: progress)) left")
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                    .font(.footnote)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Shows the episode's details")

            HStack(spacing: 12) {
                Button(action: onResume) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 15, weight: .bold))
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundStyle(AppColor.Accent.soft)
                        .frame(width: 18, height: 18)
                        .offset(x: isPlaying ? 0 : 1)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.black))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isPlaying ? Text("Pause") : Text("Resume"))

                ProgressBar(progress: progress)
            }
        }
        // Ink on mustard in both modes (the mustard doesn't flip).
        .foregroundStyle(AppColor.Text.onPastel)
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.Accent.soft)
        .contextMenu {
            Button("Resume", systemImage: "play.fill", action: onResume)
            Button("Details", systemImage: "info.circle", action: onOpen)
            Button("Remove", systemImage: "minus.circle", role: .destructive, action: onRemove)
        }
    }
}

/// How far it got: a thin ink line on a faint track.
private struct ProgressBar: View {

    let progress: Double

    var body: some View {
        Capsule()
            .fill(AppColor.Text.onPastel.opacity(0.2))
            .frame(height: 4)
            .overlay(alignment: .leading) {
                GeometryReader { geometry in
                    Capsule()
                        .fill(AppColor.Text.onPastel)
                        .frame(width: geometry.size.width * min(max(progress, 0), 1))
                        .animation(.linear(duration: 0.3), value: progress)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Progress")
            .accessibilityValue(Text("\(Int(progress * 100)) percent"))
    }
}
