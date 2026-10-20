//
//  TopPodcastCard.swift
//  Podcast
//

import SwiftUI

/// A category's number 1: its cover big, a large "1", the name in serif and
/// a lavender "Listen" that plays its newest episode.
struct TopPodcastCard: View {

    let podcast: Podcast
    let isPreparing: Bool
    let onOpen: () -> Void
    let onListen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            Color.clear
                .frame(height: 300)
                .overlay { PodcastImage(source: podcast.artworkUrl600) }
                .overlay {
                    LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .center, endPoint: .bottom)
                }
                .overlay(alignment: .topLeading) {
                    Text(1, format: .number)
                        .font(.system(size: 54, weight: .bold, design: .serif))
                        .foregroundStyle(.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.25), radius: 8)
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .accessibilityLabel(Text("Number 1"))
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(podcast.trackName ?? "")
                            .font(AppFont.title)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        Text(podcast.artistName ?? "")
                            .font(AppFont.footnote)
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 18)
                    // Room for the Listen pill under it.
                    .padding(.bottom, 62)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        // On top of the card's button: its own target.
        .overlay(alignment: .bottomLeading) {
            listenButton
                .padding(18)
        }
    }

    private var listenButton: some View {
        Button(action: onListen) {
            HStack(spacing: 6) {
                if isPreparing {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(AppColor.Text.onPastel)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .bold))
                }
                Text("Listen")
                    .font(AppFont.captionStrong)
            }
            .foregroundStyle(AppColor.Text.onPastel)
            .padding(.horizontal, 14)
            .frame(height: 30)
            .background(AppColor.Accent.soft, in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .disabled(isPreparing)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    TopPodcastCard(podcast: .mock, isPreparing: false, onOpen: {}, onListen: {})
        .padding()
}
