//
//  NewEpisodesPile.swift
//  Podcast
//

import SwiftUI

/// A pile of covers, slightly turned: one per podcast you follow with a new
/// episode. Swipe the top one sideways for the next; the pill plays it,
/// tapping the cover opens the podcast.
struct NewEpisodesPile: View {

    let items: [NewEpisodesViewModel.Item]
    let onOpenPodcast: (Podcast) -> Void
    let onPlay: (Episode) -> Void

    /// Which item is on top. Owned here: it's just where you are in the pile.
    @State private var topIndex = 0
    @State private var dragX: CGFloat = 0

    private static let side: CGFloat = 250
    /// Tilt of the cards under the top one, by depth.
    private static let tilts: [Double] = [-2, 5, -8]
    private static let swipeDistance: CGFloat = 80

    /// The top card and up to two under it, with their depth (0 = top).
    private var visible: [(item: NewEpisodesViewModel.Item, depth: Int)] {
        guard !items.isEmpty else { return [] }
        let count = min(3, items.count)
        return (0..<count).map { depth in
            (items[(topIndex + depth) % items.count], depth)
        }
    }

    private var current: NewEpisodesViewModel.Item? {
        items.isEmpty ? nil : items[topIndex % items.count]
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                ForEach(visible, id: \.item.id) { entry in
                    card(entry.item, depth: entry.depth)
                        .zIndex(Double(-entry.depth))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: Self.side + 24)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { if let current { onPlay(current.episode) } }
            .accessibilityAction(named: Text("Open podcast")) { if let current { onOpenPodcast(current.podcast) } }
            .accessibilityAdjustableAction { direction in
                if direction == .increment { advance() }
            }

            if items.count > 1 {
                Text("Swipe the pile for the next one")
                    .font(AppFont.footnote)
                    .foregroundStyle(AppColor.Text.secondary)
                    .accessibilityHidden(true)
            }
        }
        // A new list (followed/unfollowed, played) starts again from the top.
        .onChange(of: items.map(\.id)) { topIndex = 0 }
    }

    // MARK: - Card

    private func card(_ item: NewEpisodesViewModel.Item, depth: Int) -> some View {
        let isTop = depth == 0
        return ZStack(alignment: .bottomLeading) {
            Button {
                onOpenPodcast(item.podcast)
            } label: {
                Color.clear
                    .frame(width: Self.side, height: Self.side)
                    .overlay { PodcastImage(source: item.podcast.artworkUrl600 ?? item.episode.imageUrl) }
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .buttonStyle(.plain)

            if isTop {
                playPill(item)
                    .padding(14)
                    .transition(.opacity)
            }
        }
        .shadow(color: .black.opacity(0.18), radius: 14, y: 10)
        .rotationEffect(.degrees(Self.tilts[depth] + (isTop ? Double(dragX / 20) : 0)))
        .offset(x: isTop ? dragX : CGFloat(depth) * 12, y: CGFloat(depth) * -8)
        .gesture(swipe, isEnabled: isTop && items.count > 1)
        .allowsHitTesting(isTop)
    }

    private func playPill(_ item: NewEpisodesViewModel.Item) -> some View {
        Button {
            onPlay(item.episode)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("New · \(item.episode.title)")
                    .font(AppFont.captionStrong)
                    .lineLimit(1)
            }
            .foregroundStyle(AppColor.Accent.strong)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(AppColor.Surface.raised.opacity(0.94), in: Capsule())
            .contentShape(Capsule())
            // Hugs its text; a long title is cut to fit the cover.
            .frame(maxWidth: Self.side - 28, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Swipe

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                dragX = value.translation.width
            }
            .onEnded { value in
                let distance = abs(value.predictedEndTranslation.width)
                if distance > Self.swipeDistance {
                    advance()
                } else {
                    withAnimation(AppAnimation.gestureRelease) { dragX = 0 }
                }
            }
    }

    /// The top card goes to the back of the pile.
    private func advance() {
        guard items.count > 1 else { return }
        withAnimation(AppAnimation.gestureRelease) {
            topIndex = (topIndex + 1) % items.count
            dragX = 0
        }
    }

    private var accessibilityText: Text {
        guard let current else { return Text(verbatim: "") }
        return Text("New episode of \(current.podcast.trackName ?? ""): \(current.episode.title)")
    }
}

#Preview {
    NewEpisodesPile(
        items: Episode.mocks.prefix(3).enumerated().map { index, episode in
            .init(
                podcast: Podcast(trackId: index, trackName: "Podcast \(index)", artistName: nil,
                                 artworkUrl600: nil, primaryGenreName: nil, trackCount: nil, feedUrl: nil),
                episode: episode
            )
        },
        onOpenPodcast: { _ in },
        onPlay: { _ in }
    )
    .padding()
}
