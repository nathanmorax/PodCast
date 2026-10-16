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
    
    @Environment(\.playerManager) private var playerManager
    
    private var viewModel: AVPlayerViewModel {
        playerManager.viewModel
    }
    
    private var transcript: TranscriptViewModel {
        playerManager.transcript
    }
    
    /// Owned by the view: created once per episode and kept across body re-evaluations.
    @State private var actionViewModel: EpisodeActionViewModel

    init(episode: Episode) {
        self.episode = episode
        _actionViewModel = State(initialValue: EpisodeActionViewModel(episode: episode))
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
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
        .onChange(of: episode.streamUrl) { _, _ in
            // @State ignores new init values, so rebuild the VM when the episode changes.
            actionViewModel = EpisodeActionViewModel(episode: episode)
        }
    }
    
    // MARK: - Normal View
    
    private var normalView: some View {
        VStack(spacing: 0) {
            topBar
            // The artwork is the only flexible element: it takes whatever height
            // is left after the text and controls, so nothing gets pushed off
            // screen on small iPhones and it grows on Pro Max / iPad.
            artwork
                .padding(.vertical, 20)
            episodeInfo
            progressSection
                .padding(.top, 24)
            controlsSection
                .padding(.top, 28)
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Artwork
    
    private var hasArtwork: Bool {
        !(episode.imageUrl ?? "").isEmpty
    }
    
    private var artwork: some View {
        // A clear square defines the box; the image fills it via overlay.
        // With `.fill` alone the image would size itself from its own pixels and
        // overflow; this way any aspect ratio (square, 16:9…) is center-cropped
        // to the same square.
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                PodcastImage(source: episode.imageUrl, contentMode: .fill)
            }
            .overlay {
                if !hasArtwork {
                    Image(systemName: "waveform")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.gray.opacity(0.5))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 12)
            // Apple Music–style feedback: the cover "breathes" in when playing.
            .scaleEffect(viewModel.isPlaying ? 1 : 0.88)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: viewModel.isPlaying)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true) // decorative: title and author are read below
    }
    
    // MARK: - Transcript states
    
    /// Shown while the transcript is being generated: grey placeholder lines that
    /// gently pulse, shaped like the text that's coming. No spinner, no
    /// "Descargando audio…" status: that's plumbing the listener doesn't care about.
    private var transcriptPlaceholder: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Constant, never-changing rows, so a static range is fine here.
            ForEach(0..<9, id: \.self) { row in
                Text(Self.placeholderLines[row % Self.placeholderLines.count])
                    .font(.system(size: 19))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .redacted(reason: .placeholder)
        .foregroundStyle(.gray.opacity(0.25))
        .phaseAnimator([1.0, 0.45]) { content, opacity in
            content.opacity(opacity)
        } animation: { _ in
            .easeInOut(duration: 1.1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cargando transcripción")
    }
    
    private static let placeholderLines = [
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do",
        "Ut enim ad minim veniam, quis nostrud",
        "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum",
        "Excepteur sint occaecat cupidatat non proident",
    ]
    
    /// One quiet line and a retry link, instead of red text in a box.
    private func errorView(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No se pudo generar la transcripción.")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.black)
            
            Button("Intentar de nuevo") {
                Task { await runTranscription() }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHint(error)
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
                    
                    // Opening the transcript always starts generating it, so "no
                    // segments yet" means "loading" (also covers the frame before
                    // isLoading flips to true, which used to flash an empty state).
                    if let error = transcript.error {
                        errorView(error)
                            .padding(.top, 24)
                    } else if transcript.segments.isEmpty {
                        transcriptPlaceholder
                            .transition(.opacity)
                    } else {
                        ForEach(transcript.segments) { segment in
                            segmentRow(segment, proxy: proxy)
                        }
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
    }
    
    // MARK: - Episode Info
    
    private var episodeInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(episode.author)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(episode.title)
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(.black)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                // Cap very long titles so they can't squeeze the artwork to nothing.
                .lineLimit(3)
                .minimumScaleFactor(0.8)
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
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Use the bar's real width, not the screen's.
                        guard geo.size.width > 0 else { return }
                        let percentage = Float(value.location.x / geo.size.width)
                        viewModel.seek(to: min(max(percentage, 0), 1))
                    }
            )
        }
        .frame(height: 2)
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
            toggleTranscript()
        } label: {
            Group {
                if transcript.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.black)
                } else {
                    Image(systemName: transcript.segments.isEmpty ? "captions.bubble" : "captions.bubble.fill")
                        .font(.system(size: 20, weight: .regular))
                }
            }
            .foregroundStyle(.black)
            .frame(width: 28, height: 28)
        }
        .accessibilityLabel(mode == .transcript ? "Cerrar transcripción" : "Transcripción")
    }
    
    /// Opens the transcript screen (closes it if it's already open).
    /// Only generates the first time: a cached or in-progress transcript just opens.
    private func toggleTranscript() {
        if mode == .transcript {
            mode = .normal
            return
        }
        mode = .transcript
        if transcript.segments.isEmpty && !transcript.isLoading {
            Task { await runTranscription() }
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
                    playerManager.collapse()
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
        .environment(\.playerManager, .preview)
}
