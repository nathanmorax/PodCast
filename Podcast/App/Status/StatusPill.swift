//
//  StatusPill.swift
//  Podcast
//

import SwiftUI

/// The pill itself: a ring (filling with the progress) or an icon, and a
/// few words, on glass. "◔ Downloading", "Offline", "✓ Downloaded",
/// "◌ Updating", and what you just did: "Saved", "Unfollowed"…
struct StatusPill: View {

    let status: AppStatus

    var body: some View {
        HStack(spacing: 8) {
            lead
            Text(word)
                .font(AppFont.label)
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
        }
        .padding(.leading, 10)
        .padding(.trailing, 14)
        .frame(height: 34)
        .glassEffect(.regular, in: .capsule)
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var lead: some View {
        switch status {
        case .downloading(let progress, let count):
            HStack(spacing: 4) {
                ProgressRing(progress: progress, color: AppColor.Accent.soft)
                if count > 1 {
                    Text(count, format: .number)
                        .font(AppFont.captionStrong)
                        .monospacedDigit()
                        .foregroundStyle(AppColor.Accent.soft)
                }
            }
        case .updating:
            SpinningRing(color: AppColor.Status.info)
        case .offline:
            icon("wifi.slash", AppColor.Status.critical)
        case .downloaded:
            icon("checkmark", AppColor.Accent.strong)
        case .failed:
            icon("exclamationmark", AppColor.Status.critical)
        case .saved:
            icon("bookmark.fill", AppColor.Accent.strong)
        case .unsaved:
            icon("bookmark.slash", AppColor.Text.secondary)
        case .followed:
            icon("checkmark", AppColor.Accent.strong)
        case .unfollowed:
            icon("minus", AppColor.Text.secondary)
        case .downloadRemoved:
            icon("trash", AppColor.Text.secondary)
        case .downloadCanceled:
            icon("xmark", AppColor.Text.secondary)
        case .removedFromHistory:
            icon("clock.arrow.circlepath", AppColor.Text.secondary)
        }
    }

    private func icon(_ name: String, _ color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(color)
            .frame(width: 18, height: 18)
    }

    private var word: LocalizedStringKey {
        switch status {
        case .downloading: "Downloading"
        case .updating: "Updating"
        case .offline: "Offline"
        case .downloaded: "Downloaded"
        case .failed: "Download failed"
        case .saved: "Episode saved"
        case .unsaved: "Removed from Saved"
        case .followed: "Following"
        case .unfollowed: "Unfollowed"
        case .downloadRemoved: "Download removed"
        case .downloadCanceled: "Download canceled"
        case .removedFromHistory: "Removed from history"
        }
    }
}

/// A ring that fills clockwise from the top.
private struct ProgressRing: View {

    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle().stroke(AppColor.Text.primary.opacity(0.18), lineWidth: 2.4)
            Circle()
                .trim(from: 0, to: max(0.03, min(progress, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.3), value: progress)
        }
        .frame(width: 18, height: 18)
    }
}

/// A short arc going round: something's happening, no percentage.
private struct SpinningRing: View {

    let color: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().stroke(AppColor.Text.primary.opacity(0.18), lineWidth: 2.4)
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(color, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                .phaseAnimator([0.0, 360.0]) { arc, angle in
                    arc.rotationEffect(.degrees(reduceMotion ? 0 : angle))
                } animation: { angle in
                    angle == 0 ? nil : .linear(duration: 1)
                }
        }
        .frame(width: 18, height: 18)
    }
}
