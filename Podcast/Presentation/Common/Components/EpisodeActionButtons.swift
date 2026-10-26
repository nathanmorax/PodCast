//
//  EpisodeActionButtons.swift
//  Podcast
//

import SwiftUI

/// Save and Download for one episode, the same everywhere (the episode's
/// page and its sheet): just the glyph, small, no circle behind it (the
/// touch area stays 44 pt). Outlined and muted while off; filled in the
/// accent once it's on (downloaded, saved).
///
/// Download does what its state says:
/// - not downloaded (or it failed): download;
/// - downloading: a ring fills with the progress, a ■ in it; tap cancels;
/// - downloaded: the same arrow, filled in color; tap asks before
///   removing the file.
struct EpisodeDownloadButton: View {

    let actions: EpisodeActionViewModel
    var style: EpisodeActionStyle = .round

    @State private var confirmsRemoval = false

    private var state: DownloadState { actions.downloadState }

    var body: some View {
        Button(action: tap) {
            switch style {
            case .round:
                EpisodeActionIcon(isOn: isDownloaded) { glyph }
            case .labeled:
                EpisodeActionLabel(title: title, isOn: isDownloaded) { glyph }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: isDownloaded) { _, done in done }
        .accessibilityLabel(label)
        .confirmationDialog("Remove download?", isPresented: $confirmsRemoval, titleVisibility: .visible) {
            Button("Remove download", role: .destructive) { actions.deleteDownload() }
        } message: {
            Text("You can download it again later.")
        }
    }

    @ViewBuilder
    private var glyph: some View {
        switch state {
        case .downloading(let progress):
            DownloadProgressGlyph(progress: progress)
        case .waiting:
            DownloadProgressGlyph(progress: 0)
        case .downloaded:
            Image(systemName: "arrow.down.circle.fill")
        case .failed:
            Image(systemName: "arrow.clockwise.circle")
        case .idle:
            Image(systemName: "arrow.down.circle")
        }
    }

    /// The word under/next to the glyph (labeled style).
    private var title: LocalizedStringKey {
        switch state {
        case .idle: "Download"
        case .waiting, .downloading: "Downloading"
        case .downloaded: "Downloaded"
        case .failed: "Retry"
        }
    }

    private var isDownloaded: Bool {
        if case .downloaded = state { return true }
        return false
    }

    private func tap() {
        switch state {
        case .idle, .failed: actions.download()
        case .waiting, .downloading: actions.cancelDownload()
        case .downloaded: confirmsRemoval = true
        }
    }

    private var label: Text {
        switch state {
        case .idle: Text("Download")
        case .waiting, .downloading: Text("Cancel download")
        case .downloaded: Text("Remove download")
        case .failed: Text("Retry download")
        }
    }
}

/// Save (bookmark): outline when not saved, filled once saved.
struct EpisodeSaveButton: View {

    let actions: EpisodeActionViewModel
    var style: EpisodeActionStyle = .round

    var body: some View {
        Button {
            actions.toggleBookmark()
        } label: {
            switch style {
            case .round:
                EpisodeActionIcon(isOn: actions.isBookmarked) { glyph }
            case .labeled:
                EpisodeActionLabel(title: actions.isBookmarked ? "Saved" : "Save", isOn: actions.isBookmarked) { glyph }
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: actions.isBookmarked) { _, saved in saved }
        .accessibilityLabel(actions.isBookmarked ? Text("Saved") : Text("Save"))
    }

    private var glyph: some View {
        Image(systemName: actions.isBookmarked ? "bookmark.fill" : "bookmark")
            .contentTransition(.symbolEffect(.replace))
    }
}

/// How the actions look: a glyph in a circle, or a small glyph with its
/// word (the sheet's thin row).
enum EpisodeActionStyle {
    case round
    case labeled
}

/// A small glyph and its word, muted, 44 pt tall.
struct EpisodeActionLabel<Glyph: View>: View {

    let title: LocalizedStringKey
    var isOn = false
    @ViewBuilder let glyph: () -> Glyph

    var body: some View {
        HStack(spacing: 6) {
            glyph()
                .font(.system(size: 13, weight: .regular))
                .frame(width: 18, height: 18)
            Text(title)
                .font(AppFont.footnote)
        }
        .foregroundStyle(isOn ? AppColor.Accent.strong : AppColor.Text.secondary)
        .frame(height: 44)
        .contentShape(Rectangle())
    }
}

/// Just the glyph, small, in a 44 pt touch area: muted while off, in the
/// accent when on.
struct EpisodeActionIcon<Glyph: View>: View {

    var isOn = false
    @ViewBuilder let glyph: () -> Glyph

    var body: some View {
        glyph()
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(isOn ? AppColor.Accent.strong : AppColor.Text.secondary)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }
}

/// ■ inside a ring that fills with the progress (like the App Store's).
private struct DownloadProgressGlyph: View {

    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColor.Text.primary.opacity(0.2), lineWidth: 2)
            Circle()
                .trim(from: 0, to: max(0.03, min(progress, 1)))
                .stroke(AppColor.Text.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.3), value: progress)
            Image(systemName: "stop.fill")
                .font(.system(size: 6, weight: .bold))
        }
        .frame(width: 17, height: 17)
    }
}
