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
            actionsRow
            metaRow
            aboutSection
        }
    }//
    
    // MARK: - Hero
    

    private var artworkURL: String? {
        podcast.artworkURL?.absoluteString ?? podcast.artworkUrl600
    }

    /// The cover, edge to edge and under the status bar. It fades into the
    /// page at the bottom, where the podcast's name sits. It's the only
    /// flexible part, so pulling down past the top stretches it.
    private var heroSection: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: HeaderStyle.heroHeight, maxHeight: .infinity)
            .overlay {
                PodcastImage(source: artworkURL, contentMode: .fill)
            }
            // Keeps the status bar and the back button readable on any cover.
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color(.systemBackground).opacity(0.55), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 130)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, Color(.systemBackground)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 190)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    if let artist = podcast.artistName, !artist.isEmpty {
                        Text(artist)
                            .font(.system(size: 13, weight: .bold))
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(podcast.trackName ?? "")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, HeaderStyle.horizontalPadding)
                .padding(.bottom, 4)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
            .clipped()
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
                Text("\(count) episodes")
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
                    Text("Loading description…")
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
                withAnimation(AppAnimation.disclosure) {
                    isAboutExpanded.toggle()
                }
            } label: {
                (isAboutExpanded ? Text("Show less") : Text("Read more"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(AppColor.lavender))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(AppAnimation.disclosure) {
                isAboutExpanded.toggle()
            }
        }
    }
}
