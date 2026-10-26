//
//  EpisodeInfoSheet.swift
//  Podcast
//

import SwiftUI

/// An episode's details, read like an article: byline, the title in serif,
/// its first sentence as a highlighted quote, the rest of the show notes,
/// and a thin row of actions at the bottom (listen, save, download, share).
struct EpisodeInfoSheet: View {

    let episode: Episode
    let onPlay: () -> Void

    /// Save and download state for this episode.
    @State private var actions: EpisodeActionViewModel

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                byline
                    .padding(.top, 12)

                Text(episode.title)
                    .font(AppFont.title)
                    .foregroundStyle(AppColor.Text.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                if let quote = notes.quote {
                    QuoteView(text: quote)
                }

                if !notes.rest.isEmpty {
                    Text(notes.rest)
                        .font(AppFont.body)
                        .foregroundStyle(AppColor.Text.primary.opacity(0.78))
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) { actionsRow }
        .background(AppColor.paper.ignoresSafeArea())
    }

    // MARK: - Byline

    private var byline: some View {
        HStack(spacing: 10) {
            Color.clear
                .frame(width: 30, height: 30)
                .overlay { PodcastImage(source: episode.imageUrl) }
                .clipShape(Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("By \(episode.author)")
                    .font(AppFont.captionStrong)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(episode.pubDate, format: .dateTime.day().month(.wide).year())
                    Text(verbatim: "·")
                    Text(episode.durationDisplayText)
                    DownloadedBadge(episode: episode)
                }
                .font(AppFont.caption)
                .foregroundStyle(AppColor.Text.secondary)
            }
        }
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
