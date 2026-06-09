//
//  EpisodeHeaderView.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//

import SwiftUI

// MARK: - Style Constants

private enum HeaderStyle {
    static let artworkSize: CGFloat = 260
    static let artworkCornerRadius: CGFloat = 12
    static let heroHeight: CGFloat = 420
    static let horizontalPadding: CGFloat = 24
    static let collapsedLineLimit = 2
}

struct EpisodeHeaderView: View {
    
    let podcast: Podcast
    var isFavorite: Bool = false
    var podcastDescription: String?
    var isLoadingDescription: Bool = false
    let actions: EpisodeHeaderActions
    
    @State private var isAboutExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            heroSection
                .ignoresSafeArea(edges: .top)
            actionsRow
            metaRow
            aboutSection
        }
    }//
    
    // MARK: - Hero
    

    private var artworkURL: String? {
        podcast.artworkURL?.absoluteString ?? podcast.artworkUrl600
    }

    private var heroSection: some View {
        ZStack {
            DynamicPodcastHeroBackground(imageURL: artworkURL)

            VStack(spacing: 14) {
                PodcastImage(source: artworkURL)
                    .frame(width: HeaderStyle.artworkSize, height: HeaderStyle.artworkSize)
                    .clipShape(RoundedRectangle(cornerRadius: HeaderStyle.artworkCornerRadius))
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)

                Text(podcast.artistName ?? "")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.top, 56)
        }
        .frame(height: HeaderStyle.heroHeight)
        .frame(maxWidth: .infinity)
        .clipped()
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Acciones
    
    private var actionsRow: some View {
        HStack(spacing: 10) {
            Button(action: { actions.send(.play) }) {
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
            }
            
            Spacer(minLength: 8)
            
            CircleIconButton(
                systemName: isFavorite ? "bookmark.fill" : "bookmark",
                isHighlighted: isFavorite,
                action: { /*actions.send(.bookmark(podcast))*/ }
            )
            CircleIconButton(systemName: "arrow.down.to.line", action:{ actions.send(.download)})
        }
        .padding(.horizontal, HeaderStyle.horizontalPadding)
        .padding(.top, 20)
    }
    
    // MARK: - Meta
    
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
    
    // MARK: - About this podcast (colapsable)
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About this podcast")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
            
            if isLoadingDescription {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Cargando descripción...")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            } else if let description = podcastDescription, !description.isEmpty {
                expandableDescription(description)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, HeaderStyle.horizontalPadding)
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private func expandableDescription(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(description)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .lineLimit(isAboutExpanded ? nil : HeaderStyle.collapsedLineLimit)
            
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isAboutExpanded.toggle()
                }
            } label: {
                Text(isAboutExpanded ? "Show less" : "Read more")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(AppColor.lavender))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                isAboutExpanded.toggle()
            }
        }
    }
}

struct WaveformIcon: View {
    @State private var animate = false
    
    private let heights: [CGFloat] = [0.4, 1.0, 0.6, 0.9, 0.5]
    private let delays: [Double]   = [0.0, 0.15, 0.05, 0.20, 0.10]
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green)
                    .frame(width: 3, height: 16)
                    .scaleEffect(
                        y: animate ? heights[i] : 0.35,
                        anchor: .center
                    )
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(delays[i]),
                        value: animate
                    )
            }
        }
        .frame(width: 42, height: 42)
        .background(Color.green.opacity(0.1), in: Circle())
        .onAppear { animate = true }
    }
}


struct DynamicPodcastHeroBackground: View {
    let imageURL: String?

    var body: some View {
        ZStack {
            PodcastImage(source: imageURL)
                .scaledToFill()
                .blur(radius: 55)
                .scaleEffect(1.5)
                .saturation(1.5)
                .brightness(-0.08)

            LinearGradient(
                colors: [.black.opacity(0.1), .clear, .black.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipped()
    }
}
