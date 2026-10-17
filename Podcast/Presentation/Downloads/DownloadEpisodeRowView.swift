//
//  DownloadEpisodeRowView.swift
//  Podcast
//
//  Created by Jesus Mora on 19/03/26.
//
import SwiftUI

struct DownloadEpisodeRowView: View {
    let viewModel: EpisodeActionViewModel

    // The tilted cover "peeks" above the card. That overhang is now part of the
    // layout (the card starts `coverOverhang` points down) instead of a negative
    // .offset, which moved the drawing but not the space the row reported,
    // so the cover was painted over the previous cell.
    private let coverSize: CGFloat = 95
    private let coverOverhang: CGFloat = 28

    var body: some View {
        ZStack(alignment: .topLeading) {
            card
                .padding(.top, coverOverhang)

            PodcastImage(source: viewModel.episode.imageUrl)
                .frame(width: coverSize, height: coverSize)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .rotationEffect(.degrees(-4))
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
                .padding(.leading, 20)
        }
        .padding(.horizontal, 12)
    }

    private var card: some View {
        HStack(alignment: .center, spacing: 12) {
            // Reserves the cover's width so the text never runs under it.
            Color.clear
                .frame(width: coverSize)

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.episode.title)
                    .font(AppFont.itemTitle)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)

                Text(viewModel.episode.author)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.Text.secondary)
                    .lineLimit(1)

                Button {
                    viewModel.playOrPause()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 10, weight: .semibold))

                        Text(viewModel.episode.durationDisplayText)
                            .font(AppFont.captionStrong)
                    }
                    .foregroundStyle(AppColor.Text.primary)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(Capsule().fill(Color.black.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 20)
        .padding(.trailing, 16)
        .padding(.vertical, 16)
        // Tall enough for the part of the cover that sits inside the card.
        .frame(minHeight: coverSize - coverOverhang + 24)
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
