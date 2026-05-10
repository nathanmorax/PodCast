//
//  EpisodeHeaderView.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//

import SwiftUI

// MARK: - Style Constants

private enum HeaderStyle {
    static let yellow = Color(red: 0.96, green: 0.96, blue: 0.40)
    static let cardCornerRadius: CGFloat = 16
    static let horizontalPadding: CGFloat = 24
    static let cardOverlap: CGFloat = 80   // cuánto sobresale la card de la imagen
}

// MARK: - Main Header View

struct EpisodeHeaderViewUI: View {
    
    let podcast: Podcast
    var isFavorite: Bool = false
    
    var onPlay: () -> Void = {}
    var onBookmark: () -> Void = {}
    var onDownload: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            heroSection
            actionsRow
            metaRow
            aboutSection
        }
    }
    
    // MARK: - Hero (imagen + tarjeta amarilla flotante)
    
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            PodcastImage(source: podcast.artworkUrl600)
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
            
            yellowCard
                .padding(.horizontal, HeaderStyle.horizontalPadding)
                .offset(y: HeaderStyle.cardOverlap)
        }
        .padding(.bottom, HeaderStyle.cardOverlap) // compensa el offset
    }
    
    private var yellowCard: some View {
        VStack(spacing: 10) {
            Text(podcast.trackName ?? "")
                .font(.custom("NewYorkLarge-Bold", size: 28))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
            
            Text(podcast.artistName ?? "")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.black.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(HeaderStyle.yellow)
        .clipShape(RoundedRectangle(cornerRadius: HeaderStyle.cardCornerRadius))
    }
    
    // MARK: - Acciones (Play + bookmark + download)
    
    private var actionsRow: some View {
        HStack(spacing: 10) {
            Button(action: onPlay) {
                HStack(spacing: 10) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32, weight: .regular))
                    Text("Play Podcast")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.black)
                .padding(.vertical, 10)
                .padding(.leading, 8)
                .padding(.trailing, 24)
                .background(HeaderStyle.yellow, in: Capsule())
            }
            
            Spacer(minLength: 8)
            
            CircleIconButton(
                systemName: isFavorite ? "bookmark.fill" : "bookmark",
                isHighlighted: isFavorite,
                action: onBookmark
            )
            CircleIconButton(systemName: "arrow.down.to.line", action: onDownload)
        }
        .padding(.horizontal, HeaderStyle.horizontalPadding)
        .padding(.top, 20)
    }
    
    // MARK: - Meta (episodios + género)
    
    private var metaRow: some View {
        HStack {
            if let count = podcast.trackCount {
                Text("\(count) episodios")
            }
            Spacer()
            if let genre = podcast.primaryGenreName {
                Text(genre)
            }
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, HeaderStyle.horizontalPadding)
        .padding(.top, 16)
    }
    
    // MARK: - About this podcast
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this podcast")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
            
            Text(podcast.trackName ?? "")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, HeaderStyle.horizontalPadding)
        .padding(.top, 20)
    }

}

// MARK: - Circle Icon Button (bookmark / download)

private struct CircleIconButton: View {
    let systemName: String
    var isHighlighted: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(isHighlighted ? .white : .black)
                .frame(width: 44, height: 44)
                .background(
                    isHighlighted
                        ? Color(AppColor.lavender)
                        : Color(.systemGray6),
                    in: Circle()
                )
                .animation(.easeInOut(duration: 0.2), value: isHighlighted)
        }
    }
}

// MARK: - Preview


#Preview("Header — mock") {
    ScrollView {
        EpisodeHeaderViewUI(
            podcast: .mock,
            onPlay:     { print("▶️ play tapped") },
            onBookmark: { print("🔖 bookmark tapped") },
            onDownload: { print("⬇️ download tapped") }
        )
    }
    .ignoresSafeArea(edges: .top)
}

#Preview("Header — sizeThatFits", traits: .sizeThatFitsLayout) {
    EpisodeHeaderViewUI(podcast: .mock)
}
