//
//  EpisodeInfoSheet.swift
//  Podcast
//

import SwiftUI

/// An episode's details in a sheet, like a magazine's audio page:
/// - a bar with ✕ on the right (glass, iOS 26);
/// - the show in serif capitals in the accent, the title in bold, the
///   artwork on the right;
/// - the description, then "With author • date · length";
/// - the rest of the show notes;
/// - a thin row of actions at the bottom (listen, save, download, share).
struct EpisodeInfoSheet: View {

    let episode: Episode
    let onPlay: () -> Void

    /// Save and download state for this episode.
    @State private var actions: EpisodeActionViewModel

    @Environment(\.dismiss) private var dismiss

    init(episode: Episode, onPlay: @escaping () -> Void) {
        self.episode = episode
        self.onPlay = onPlay
        // One-time seed: the sheet is created per episode.
        _actions = State(initialValue: EpisodeActionViewModel(episode: episode))
    }

    private var notes: EpisodeNotes {
        let full = episode.showNotes ?? ""
        return EpisodeNotes(full.isEmpty ? episode.description : full)
    }

    /// The first part of the notes (under the title); the rest goes below
    /// the byline.
    private var lead: String { notes.quote ?? "" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if !lead.isEmpty {
                    Text(lead)
                        .font(.body)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineSpacing(6)
                        .textSelection(.enabled)
                }

                byline

                if !notes.rest.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                    Text(notes.rest)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.Text.primary.opacity(0.78))
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .safeAreaInset(edge: .bottom, spacing: 0) { actionsRow }
        .background(AppColor.paper.ignoresSafeArea())
    }

    // MARK: - Top bar

    /// ✕ on the right, on glass; a hairline under it.
    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColor.Accent.strong)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(AppColor.paper)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.6)
        }
    }

    // MARK: - Header

    /// The show and the title on the left, the artwork on the right.
    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                RowOverline(text: episode.author)
                Text(episode.title)
                    .font(.system(.title2, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            RowArtwork(side: 110) {
                PodcastImage(source: episode.imageUrl)
            }
        }
    }

    // MARK: - Byline

    /// "With Café con Datos • October 22, 2026 · 41 min ↓".
    private var byline: some View {
        HStack(spacing: 6) {
            if !episode.author.isEmpty {
                Text("With \(episode.author)")
                    .fontWeight(.semibold)
                Text(verbatim: "•")
            }
            Text(episode.pubDate, format: .dateTime.day().month(.wide).year())
            Text(verbatim: "·")
            Text(episode.durationDisplayText)
            DownloadedBadge(episode: episode)
        }
        .font(.subheadline)
        .foregroundStyle(AppColor.Text.secondary)
        .lineLimit(2)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Actions

    /// Thin icons with their label, like an article's share bar.
    private var actionsRow: some View {
        HStack(spacing: 22) {
            actionButton("Listen", systemImage: "play.fill", action: onPlay)

            EpisodeSaveButton(actions: actions, style: .labeled)

            EpisodeDownloadButton(actions: actions, style: .labeled)

            Spacer(minLength: 0)

            if let url = URL(string: episode.streamUrl) {
                ShareLink(item: url, subject: Text(episode.title)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColor.Text.secondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Share")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 6)
        .background(AppColor.paper)
        .overlay(alignment: .top) {
            Divider().opacity(0.6)
        }
    }

    private func actionButton(_ title: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppFont.footnote)
                .foregroundStyle(AppColor.Text.secondary)
                .contentTransition(.symbolEffect(.replace))
                .frame(height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
