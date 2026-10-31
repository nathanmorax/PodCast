//
//  EpisodeHero.swift
//  Podcast
//

import SwiftUI

/// The top of the episode page, like its show's page: a soft wash of the
/// artwork's color fading into the page, the artwork rounded in the
/// middle, then centered the date, the title in bold, the show in the
/// accent (it opens the show) and "Science · 48 min".
struct EpisodeHero: View {

    let episode: Episode
    let showName: String?
    let genre: String?
    /// Opens the show, when it's known.
    var onOpenShow: (() -> Void)? = nil

    static let coverSide: CGFloat = 230

    @State private var loadedTint: ArtworkTint?

    private var tint: ArtworkTint? {
        loadedTint ?? ArtworkTintLoader.cachedTint(for: episode.imageUrl)
    }

    var body: some View {
        VStack(spacing: 0) {
            PodcastImage(source: episode.imageUrl, contentMode: .fill)
                .frame(width: Self.coverSide, height: Self.coverSide)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 18, y: 10)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(episode.pubDate, format: .dateTime.day().month(.wide).year())
                    .font(.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                Text(episode.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Button {
                    onOpenShow?()
                } label: {
                    Text(showName ?? episode.author)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColor.Accent.strong)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .disabled(onOpenShow == nil)
                .accessibilityHint(onOpenShow == nil ? Text(verbatim: "") : Text("Opens the podcast"))
                Text(details)
                    .font(.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 22)
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        // Room for the status and navigation bars, which float over the wash.
        .padding(.top, 110)
        .background(alignment: .top) {
            ArtworkWash(color: tint?.color, height: 360)
        }
        .task(id: episode.imageUrl) {
            guard loadedTint == nil else { return }
            let tint = await ArtworkTintLoader.tint(for: episode.imageUrl)
            withAnimation(AppAnimation.stateChange) { loadedTint = tint }
        }
    }

    /// "Science · 48 min".
    private var details: String {
        [genre, episode.durationDisplayText]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
