//
//  EpisodeDetailView.swift
//  Podcast
//

import SwiftUI

/// An episode, full screen, read like a magazine story:
/// - its artwork edge to edge, under the status bar (pinned when pulled);
/// - the podcast's name as an overline and the title in serif over the fade;
/// - a byline (author, how long ago, length);
/// - Listen, and save / download / share;
/// - the first sentence of the notes as a quote, then the rest.
struct EpisodeDetailView: View {

    let episode: Episode
    /// Shown as the overline over the title (nil: the episode's author).
    let podcastName: String?
    let pull: HeaderPull
    let onPlay: () -> Void
    /// Vertical scroll position (negative while pulled past the top).
    let onScroll: (CGFloat) -> Void

    /// Save and download state. One-time seed: the screen is made per episode.
    @State private var actions: EpisodeActionViewModel

    static let heroHeight: CGFloat = 460

    init(episode: Episode, podcastName: String?, pull: HeaderPull,
         onPlay: @escaping () -> Void, onScroll: @escaping (CGFloat) -> Void) {
        self.episode = episode
        self.podcastName = podcastName
        self.pull = pull
        self.onPlay = onPlay
        self.onScroll = onScroll
        _actions = State(initialValue: EpisodeActionViewModel(episode: episode))
    }

    private var notes: EpisodeNotes {
        let full = episode.showNotes ?? ""
        return EpisodeNotes(full.isEmpty ? episode.description : full)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero

                VStack(alignment: .leading, spacing: 22) {
                    byline
                    actionsRow

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
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
        // The artwork starts under the status bar and the (clear) navigation bar.
        .ignoresSafeArea(edges: .top)
        .background(AppColor.screenBackground.ignoresSafeArea())
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            onScroll(offset)
        }
    }

    // MARK: - Hero

    private var hero: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: Self.heroHeight)
            .background(alignment: .top) {
                PinnedCover(source: episode.imageUrl, height: Self.heroHeight, pull: pull)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, AppColor.screenBackground],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 220)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(podcastName ?? episode.author)
                        .overlineStyle()
                        .lineLimit(1)
                    Text(episode.title)
                        .font(AppFont.title)
                        .foregroundStyle(AppColor.Text.primary)
                        .lineLimit(4)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
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
                HStack(spacing: 0) {
                    Text(episode.pubDate, format: .relative(presentation: .named, unitsStyle: .wide))
                    Text(verbatim: " · \(episode.durationDisplayText)")
                }
                .font(AppFont.caption)
                .foregroundStyle(AppColor.Text.secondary)
                .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Actions

    /// Listen (lavender pill), then save, download and share as circles —
    /// the same row as the podcast page.
    private var actionsRow: some View {
        HStack(spacing: 10) {
            Button(action: onPlay) {
                Label("Listen", systemImage: "play.fill")
                    .font(AppFont.button)
                    .foregroundStyle(AppColor.Text.onPastel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Capsule().fill(AppColor.Accent.soft))
            }
            .buttonStyle(.plain)

            Button {
                actions.toggleBookmark()
            } label: {
                roundIcon(actions.isBookmarked ? "bookmark.fill" : "bookmark", isOn: actions.isBookmarked)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: actions.isBookmarked)
            .accessibilityLabel(actions.isBookmarked ? Text("Saved") : Text("Save"))

            Button {
                switch actions.downloadState {
                case .idle, .failed: actions.download()
                default: break
                }
            } label: {
                roundIcon(downloadIcon, isOn: isDownloaded)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(downloadLabel)

            if let url = URL(string: episode.streamUrl) {
                ShareLink(item: url, subject: Text(episode.title)) {
                    roundIcon("square.and.arrow.up")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share")
            }
        }
    }

    private var isDownloaded: Bool {
        if case .downloaded = actions.downloadState { return true }
        return false
    }

    private var downloadIcon: String {
        switch actions.downloadState {
        case .downloaded: "checkmark"
        case .downloading, .waiting: "arrow.down.circle.dotted"
        default: "arrow.down"
        }
    }

    private var downloadLabel: Text {
        switch actions.downloadState {
        case .downloaded: Text("Downloaded")
        case .downloading, .waiting: Text("Downloading")
        default: Text("Download")
        }
    }

    /// Small, light glyphs in 44 pt circles (the touch target stays 44).
    private func roundIcon(_ name: String, isOn: Bool = false) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .medium))
            .contentTransition(.symbolEffect(.replace))
            .foregroundStyle(isOn ? AppColor.Text.onPastel : AppColor.Text.primary)
            .frame(width: 44, height: 44)
            .background(Circle().fill(isOn ? AppColor.Accent.soft : AppColor.Text.primary.opacity(0.1)))
    }
}

#Preview {
    EpisodeDetailView(episode: .mock, podcastName: "Café con Datos", pull: HeaderPull(),
                      onPlay: {}, onScroll: { _ in })
}
