//
//  BookMarkView.swift
//  Podcast
//
//  Created by Jonathan Mora on 04/06/26.
//


import SwiftUI

struct BookMarkView: View {
    
    let viewModel: EpisodeActionViewModel
    
    let state: DownloadState

    var body: some View {
        HStack(spacing: 12) {
            
            PodcastImage(source: viewModel.episode.imageUrl)
                .frame(width: 95, height: 95)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.episode.author)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.gray)
                
                Text(viewModel.episode.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(viewModel.episode.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                

                
                HStack {
                    
                    Button {
                        
                        viewModel.playOrPause()
                        
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 10, weight: .semibold))

                            Text(viewModel.episode.durationDisplayText)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button {
                        viewModel.toggleBookmark()
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 36, height: 36)
                    }
                    .foregroundStyle(.black)
                    
                    DownloadButton(episode: viewModel.episode)
                    
                }
                
            }
        }
    }
}


struct DownloadButton: View {
    let episode: Episode
    @State private var downloadManager = DownloadManager.shared
    @State private var spinAngle: Double = 0

    private var state: DownloadState {
        downloadManager.state(for: episode)
    }

    var body: some View {
        Button {
            withAnimation { handleTap() }
        } label: {
            ZStack {
                ring
                icon
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .onChange(of: isActive) { _, active in
            if active {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    spinAngle = 360
                }
            } else {
                spinAngle = 0
            }
        }
    }

    // MARK: - Ring

    @ViewBuilder
    private var ring: some View {
        switch state {
        case .idle, .failed, .downloaded:
            EmptyView()
            
        case .waiting:
            Circle()
                .stroke(Color.black.opacity(0.4), lineWidth: 1)
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1, lineCap: .round))
                .rotationEffect(.degrees(spinAngle))
                .onAppear {
                    withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: false)) {
                        spinAngle = 360
                    }
                }
            
        case .downloading(let progress):
//            Circle()
//                .stroke(Color.black.opacity(0.15), style: StrokeStyle(lineWidth: 3, dash: [4, 4]))
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.black, style: StrokeStyle(lineWidth: 3, lineCap: .butt, dash: [4, 4]))
                .rotationEffect(.degrees(-90)) // fijo, solo para empezar desde arriba
            
        }
    }

    // MARK: - Icon

    @ViewBuilder
    private var icon: some View {
        let symbolName: String = {
            switch state {
            case .idle, .failed:    return "arrow.down.square.fill"
            case .waiting:          return "xmark"
            case .downloading:      return "xmark"
            case .downloaded:       return "arrow.down.square.fill"
            }
        }()

        Image(systemName: symbolName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(iconColor)
            .contentTransition(.symbolEffect(.replace))
            .animation(.easeInOut(duration: 0.25), value: symbolName)
    }

    // MARK: - Helpers

    private var iconColor: Color {
        switch state {
        case .idle, .failed:    return .black.opacity(0.2)
        case .waiting, .downloaded, .downloading: return .black
        }
    }

    private var isActive: Bool {
        switch state {
        case .downloading, .waiting: return true
        default:                     return false
        }
    }
    
    // MARK: - Actions

    private func handleTap() {
        switch state {
        case .idle, .failed:         downloadManager.download(episode)
        case .downloading, .waiting: downloadManager.cancelDownload(episode)
        case .downloaded:            downloadManager.deleteDownload(episode)
        }
    }
}
