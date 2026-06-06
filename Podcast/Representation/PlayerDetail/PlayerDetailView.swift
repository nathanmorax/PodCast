//
//  PlayerView.swift
//  Podcast
//

import SwiftUI

enum PlayerMode {
    case normal
    case transcript
}

struct PlayerView: View {
    
    let episode: Episode
    @State private var mode: PlayerMode = .normal
    @State private var showControls: Bool = true
    @State private var hideControlsTask: Task<Void, Never>?
    
    private var viewModel: AVPlayerViewModel {
        PlayerManager.shared.viewModel
    }
    
    private var transcript: TranscriptViewModel {
        PlayerManager.shared.transcript
    }
    
    private var actionViewModel: EpisodeActionViewModel {
        EpisodeActionViewModel(episode: episode)
    }
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            if mode == .normal {
                normalView
            } else {
                transcriptView
            }
        }
        .gesture(dismissGesture)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: mode)
        .onChange(of: viewModel.progress) { _, _ in
            transcript.updateCurrentSegment(playbackSeconds: viewModel.currentPlaybackSeconds)
        }
    }
    
    // MARK: - Normal View
    
    private var normalView: some View {
        VStack(spacing: 0) {
            topBar
            Spacer()
            episodeInfo
            Spacer()
            progressSection
            Spacer(minLength: 24)
            controlsSection
            Spacer(minLength: 8)
//            lyricsPreview
//            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Lyrics Preview
    
    private var lyricsPreview: some View {
        VStack(spacing: 12) {
            lyricsContent
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var lyricsContent: some View {
        if transcript.isLoading {
            loadingView
        } else if let error = transcript.error {
            errorView(error)
        } else if transcript.segments.isEmpty {
//            emptyStateView
        } else {
            currentSegmentView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text(transcript.progress)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding()
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 8) {
            Text(error)
                .font(.system(size: 13))
                .foregroundStyle(.red.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Button("Reintentar") {
                Task { await runTranscription() }
            }
            .font(.caption)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        Button {
            Task { await runTranscription() }
        } label: {
            Label("Generar transcripción", systemImage: "text.bubble")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(Capsule().fill(Color.black))
        }
        .padding(.top, 8)
    }
    
    private var currentSegmentView: some View {
        Button {
            mode = .transcript
        } label: {
            VStack(spacing: 6) {
                if let current = transcript.currentSegment {
                    Text(current.text)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.gray.opacity(0.5))
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Transcription
    
    private func runTranscription() async {
        if #available(iOS 26.0, *) {
            await transcript.generate(for: episode.streamUrl, episodeId: episode.streamUrl)
        }
    }
    
    // MARK: - Transcript View
    
    private var transcriptView: some View {
        ZStack(alignment: .bottom) {
            transcriptScrollView
            
            if showControls {
                compactControls
                    .padding(.bottom, 20)
                    .padding(.top, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.white.opacity(0), Color.white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showControls)
        .onAppear {
            showControls = true
            scheduleHideControls()
        }
        .onDisappear {
            hideControlsTask?.cancel()
        }
    }
    
    // MARK: - Transcript Scroll
    
    private var transcriptScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    closeButton
                    
                    ForEach(transcript.segments) { segment in
                        segmentRow(segment, proxy: proxy)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
            }
            .onChange(of: transcript.currentSegment?.id) { _, newId in
                guard let newId else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    proxy.scrollTo(newId, anchor: .center)
                }
            }
            .onAppear {
                if let id = transcript.currentSegment?.id {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }
    
    private var closeButton: some View {
        Button {
            mode = .normal
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
                Text("Player")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.gray)
            .padding(.top, 60)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
    
    private func segmentRow(_ segment: LocalTranscriptSegment, proxy: ScrollViewProxy) -> some View {
        let isCurrent = transcript.currentSegment?.id == segment.id
        return Text(segment.text)
            .font(.system(
                size: 19,
                weight: isCurrent ? .semibold : .regular
            ))
            .foregroundStyle(isCurrent ? .black : .gray.opacity(0.4))
            .lineSpacing(4)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(segment.id)
            .animation(.easeInOut(duration: 0.3), value: isCurrent)
            .onTapGesture {
                seekToSegment(segment)
                showControlsTemporarily()
            }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Text(episode.pubDate.formattedDate())
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.gray)
            Spacer()
        }
        .padding(.top, 60)
        .padding(.bottom, 4)
    }
    
    // MARK: - Episode Info
    
    private var episodeInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(episode.author)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(episode.title)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(.black)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Progress
    
    private var progressSection: some View {
        VStack(spacing: 6) {
            progressBar
            progressLabels
        }
    }
    
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 2)
                
                Capsule()
                    .fill(Color.black)
                    .frame(width: geo.size.width * CGFloat(viewModel.progress), height: 2)
            }
        }
        .frame(height: 2)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let screenWidth = UIScreen.main.bounds.width - 48
                    let percentage = Float(value.location.x / screenWidth)
                    viewModel.seek(to: min(max(percentage, 0), 1))
                }
        )
    }
    
    private var progressLabels: some View {
        HStack {
            Text(viewModel.currentTimeText)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.gray)
            
            Spacer()
            
            Text("-\(viewModel.durationText)")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.gray)
        }
    }
    
    // MARK: - Controls
    
    private var controlsSection: some View {
        HStack(alignment: .center) {
            bookmarkButton
            Spacer()
            seekBackwardButton
            Spacer()
            playPauseButton
            Spacer()
            seekForwardButton
            Spacer()
            transcriptButton
        }
    }
    
    private var bookmarkButton: some View {
        Button {
            actionViewModel.toggleBookmark()
        } label: {
            Image(systemName: actionViewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.black)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.6),
                    value: actionViewModel.isBookmarked
                )
        }
    }
    
    private var seekBackwardButton: some View {
        Button {
            viewModel.seekBackward()
        } label: {
            Image(systemName: "gobackward.15")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(.black)
        }
    }
    
    private var playPauseButton: some View {
        Button {
            viewModel.togglePlayPause()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 66, height: 66)
                
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                    .offset(x: viewModel.isPlaying ? 0 : 2)
            }
        }
    }
    
    private var seekForwardButton: some View {
        Button {
            viewModel.seekForward()
        } label: {
            Image(systemName: "goforward.15")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(.black)
        }
    }
    
    private var transcriptButton: some View {
        Button {
            Task { await runTranscription() }

        } label: {
            Image(systemName: "captions.bubble")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.black)
        }
    }
    
    // MARK: - Compact Controls (transcript)
    
    private var compactControls: some View {
        VStack(spacing: 12) {
            progressSection
                .padding(.horizontal, 24)
            
            controlsSection
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
    }
    
    // MARK: - Helpers
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }
    
    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                if value.translation.height > 100 && mode == .normal {
                    PlayerManager.shared.collapse()
                }
            }
    }
    
    private func seekToSegment(_ segment: LocalTranscriptSegment) {
        guard let last = transcript.segments.last,
              last.endTime > 0 else { return }
        let percentage = Float(segment.startTime / last.endTime)
        viewModel.seek(to: percentage)
    }
    
    private func showControlsTemporarily() {
        withAnimation { showControls = true }
        scheduleHideControls()
    }
    
    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation { showControls = false }
            }
        }
    }
}

#Preview {
    PlayerView(episode: .mock)
}
