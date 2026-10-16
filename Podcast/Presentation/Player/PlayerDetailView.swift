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
    /// The listener asked for the transcript while it was still being generated:
    /// open it by itself as soon as it's ready. No intermediate screen.
    @State private var wantsTranscript = false
    
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
            wantsTranscript = false
        }
        .onChange(of: transcript.segments.isEmpty) { _, isEmpty in
            guard !isEmpty, wantsTranscript, mode == .normal else { return }
            wantsTranscript = false
            mode = .transcript
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
            transcriptBackground
            
            transcriptScrollView
            
            if showControls {
                compactControls
                    .padding(.bottom, 20)
                    .padding(.top, 28)
                    .background(
                        // Frosted glass that fades in from the top, instead of a
                        // white gradient that only matched a white background.
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .mask(
                                LinearGradient(
                                    colors: [.clear, .black, .black],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .ignoresSafeArea()
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
    
    /// The episode's own artwork, blurred and washed with white: the transcript
    /// keeps the color of what's playing instead of jumping to a blank page,
    /// and black text stays readable on top.
    private var transcriptBackground: some View {
        Color.clear
            .overlay {
                PodcastImage(source: episode.imageUrl, contentMode: .fill)
                    .blur(radius: 50, opaque: true)
                    .scaleEffect(1.3) // hides the soft edges the blur leaves
            }
            .overlay(Color.white.opacity(0.62))
            .clipped()
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
    
    /// "Now playing" header: tiny cover + title, so the listener never loses
    /// context. Tapping it goes back to the player.
    private var closeButton: some View {
        Button {
            mode = .normal
        } label: {
            HStack(spacing: 10) {
                PodcastImage(source: episode.imageUrl)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(episode.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                    Text(episode.author)
                        .font(.system(size: 12))
                        .foregroundStyle(.black.opacity(0.5))
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.5))
            }
            .padding(.top, 60)
            .padding(.bottom, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Volver al reproductor")
    }
    
    private func segmentRow(_ segment: LocalTranscriptSegment, proxy: ScrollViewProxy) -> some View {
        let isCurrent = transcript.currentSegment?.id == segment.id
        return Text(segment.text)
            .font(.system(
                size: 19,
                weight: isCurrent ? .semibold : .regular
            ))
            .foregroundStyle(isCurrent ? .black : .black.opacity(0.3))
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
            // The only loading feedback: the icon itself breathes while the
            // transcript is generated. The player stays exactly as it is.
            Image(systemName: transcriptIcon)
                .font(.system(size: 20, weight: .regular))
                .symbolEffect(.pulse, options: .repeating, isActive: transcript.isLoading)
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(.black)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(transcriptAccessibilityLabel)
    }
    
    private var transcriptIcon: String {
        if transcript.error != nil { return "exclamationmark.bubble" }
        return transcript.segments.isEmpty ? "captions.bubble" : "captions.bubble.fill"
    }
    
    private var transcriptAccessibilityLabel: String {
        if mode == .transcript { return "Cerrar transcripción" }
        if transcript.isLoading { return "Preparando transcripción" }
        if transcript.error != nil { return "Reintentar transcripción" }
        return "Transcripción"
    }
    
    /// Opens the transcript screen (closes it if it's already open).
    /// Only generates the first time: a cached or in-progress transcript just opens.
    private func toggleTranscript() {
        if mode == .transcript {
            mode = .normal
            return
        }
        // Ready (cached or already generated): open it right away.
        guard transcript.segments.isEmpty else {
            mode = .transcript
            return
        }
        // Not ready: stay on the player; it opens by itself when done.
        wantsTranscript = true
        if !transcript.isLoading {
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
