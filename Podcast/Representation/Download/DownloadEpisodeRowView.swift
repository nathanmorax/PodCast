//
//  DownloadEpisodeRowView.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//
import SwiftUI

struct DownloadEpisodeRowView: View {
    let viewModel: EpisodeActionViewModel

//    var episode: Episode
    
    var body: some View {
        HStack(spacing: 12) {
            PodcastImage(source: viewModel.episode.imageUrl)
                .frame(width: 95, height: 95)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .rotationEffect(.degrees(-4))
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
                .offset(y: -70)
                .padding(.bottom, -50)
             
            VStack {
                Text(viewModel.episode.title)
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.center)
                
                Text(viewModel.episode.author)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
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
                
//                DownloadButton(episode: viewModel.episode)

            }

            
            Spacer()
        }
        .padding(.top, 40)
        .padding(.bottom, 30)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: 125)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(uiColor: .systemGray5))
        )
    }
}

//#Preview(traits: .sizeThatFitsLayout) {
//    FavoritesPodcastCellUI(podcast: .mock)
//        .frame(width: 280)
//        .padding(40)
//}


//struct DownloadButton: View {
//    let episode: Episode
//    @State private var downloadManager = DownloadManager.shared
//
//    private var state: DownloadState {
//        downloadManager.state(for: episode)
//    }
//
//    var body: some View {
//        Button {
//            handleTap()
//        } label: {
//            ZStack {
//                ring
//                icon
//            }
//            .frame(width: 36, height: 36)
//        }
//        .buttonStyle(.plain)
//    }
//
//    // MARK: - Ring
//
//    @ViewBuilder
//    private var ring: some View {
//        switch state {
//        case .idle:
//            Circle()
//                .stroke(Color.secondary.opacity(0.3), lineWidth: 3)
//
//        case .waiting:
//            Circle()
//                .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
//            SpinningArc()
//
//        case .downloading(let progress):
//            Circle()
//                .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
//            Circle()
//                .trim(from: 0, to: progress)
//                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
//                .rotationEffect(.degrees(-90))
//                .animation(.linear(duration: 0.3), value: progress)
//
//        case .downloaded:
//            Circle()
//                .stroke(Color.green, lineWidth: 3)
//
//        case .failed:
//            Circle()
//                .stroke(Color.red, style: StrokeStyle(lineWidth: 3, dash: [4, 4]))
//        }
//    }
//
//    // MARK: - Icon
//
//    @ViewBuilder
//    private var icon: some View {
//        switch state {
//        case .idle:
//            Image(systemName: "arrow.down")
//                .font(.system(size: 14, weight: .semibold))
//                .foregroundStyle(Color.accentColor)
//
//        case .waiting:
//            Image(systemName: "arrow.down")
//                .font(.system(size: 14, weight: .semibold))
//                .foregroundStyle(Color.accentColor)
//
//        case .downloading:
//            Image(systemName: "xmark")
//                .font(.system(size: 12, weight: .bold))
//                .foregroundStyle(Color.accentColor)
//
//        case .downloaded:
//            Image(systemName: "checkmark")
//                .font(.system(size: 14, weight: .semibold))
//                .foregroundStyle(Color.green)
//
//        case .failed:
//            Image(systemName: "arrow.down")
//                .font(.system(size: 14, weight: .semibold))
//                .foregroundStyle(Color.red)
//        }
//    }
//
//    // MARK: - Actions
//
//    private func handleTap() {
//        switch state {
//        case .idle, .failed:
//            downloadManager.download(episode)
//        case .downloading, .waiting:
//            downloadManager.cancelDownload(episode)
//        case .downloaded:
//            downloadManager.deleteDownload(episode)
//        }
//    }
//}
//
//// MARK: - Spinning arc (waiting state)
//
//struct SpinningArc: View {
//    @State private var rotation = 0.0
//
//    var body: some View {
//        Circle()
//            .trim(from: 0, to: 0.25)
//            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
//            .rotationEffect(.degrees(rotation))
//            .onAppear {
//                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
//                    rotation = 360
//                }
//            }
//    }
//}
