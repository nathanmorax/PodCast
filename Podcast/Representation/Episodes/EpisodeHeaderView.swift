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
    static let cardOverlap: CGFloat = 80
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
            actionsRow
            metaRow
            aboutSection
        }
    }
    
    // MARK: - Hero
    
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            PodcastImage(source: podcast.artworkUrl600)
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
            
            yellowCard
                .offset(y: HeaderStyle.cardOverlap)
                .aspectRatio(1, contentMode: .fit)

        }
        .padding(.bottom, HeaderStyle.cardOverlap)
    }
    
    private var yellowCard: some View {
        VStack(spacing: 10) {
            Text(podcast.trackName ?? "")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
            
            Text(podcast.artistName ?? "")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.black.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(HeaderStyle.yellow)
        .clipShape(RoundedRectangle(cornerRadius: HeaderStyle.cardCornerRadius))
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
                .background(HeaderStyle.yellow, in: Capsule())
            }
            
            Spacer(minLength: 8)
            
            CircleIconButton(
                systemName: isFavorite ? "bookmark.fill" : "bookmark",
                isHighlighted: isFavorite,
                action: { actions.send(.bookmark) }
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

// MARK: - Preview

//#Preview("Header — mock") {
//    ScrollView {
//        EpisodeHeaderView(
//            podcast: .mock,
//            podcastDescription: "Este es un podcast de prueba con una descripción larga para ver cómo se ve el botón de leer más cuando hay mucho texto que mostrar al usuario.",
//            actions: EpisodeHeaderActions()
//        )
//    }
//    .ignoresSafeArea(edges: .top)
//}
