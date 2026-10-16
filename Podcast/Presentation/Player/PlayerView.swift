//
//  PlayerView.swift
//  Podcast
//

import SwiftUI

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
    
    // MARK: - Style (soft white, near-black ink, lavender accent)
    
    private static let paper = AppColor.paper
    private static let ink = AppColor.ink
    private static let accent = AppColor.lavender
    
    private func rounded(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    
    var body: some View {
        ZStack {
            Self.paper
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
            // The cover goes edge to edge, under the status bar; the top
            // controls float on it.
            heroArtwork
                .overlay(alignment: .top) {
                    topBar
                        .padding(.horizontal, 20)
                }

            VStack(spacing: 0) {
                progressBar
                controlsSection
                    .padding(.top, 22)
                lineWheel
                    .padding(.top, 18)
                Spacer(minLength: 8)
                secondaryActions
                    .padding(.bottom, 30)
            }
            .padding(.horizontal, 28)
            .padding(.top, 4)
        }
        .ignoresSafeArea(.container, edges: .top)
    }

    // MARK: - Artwork

    private var hasArtwork: Bool {
        !(episode.imageUrl ?? "").isEmpty
    }

    /// About half the screen, full width. It fades into the paper at the
    /// bottom so the controls sit on a clean background.
    private var heroArtwork: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .containerRelativeFrame(.vertical) { height, _ in height * 0.5 }
            .overlay {
                PodcastImage(source: episode.imageUrl, contentMode: .fill)
            }
            .overlay {
                if !hasArtwork {
                    Image(systemName: "waveform")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(Self.ink.opacity(0.25))
                }
            }
            // Keeps the status bar readable on any cover.
            .overlay(alignment: .top) {
                LinearGradient(colors: [.black.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [Self.paper.opacity(0), Self.paper], startPoint: .top, endPoint: .bottom)
                    .frame(height: 150)
            }
            .clipped()
            .accessibilityHidden(true)
    }

    // MARK: - Line wheel
    
    private struct WheelLines {
        let id: String
        let previous: String?
        let current: String
        let next: String?
    }
    
    /// With a transcript: the sentence before, the one being said, and the next.
    /// Without one: the episode title and, below, who's talking (the show).
    private var wheelLines: WheelLines {
        let segments = transcript.segments
        if let index = transcript.currentIndex, segments.indices.contains(index) {
            return WheelLines(
                id: "\(index)",
                previous: index > 0 ? segments[index - 1].text : nil,
                current: segments[index].text,
                next: index + 1 < segments.count ? segments[index + 1].text : nil
            )
        }
        return WheelLines(id: episode.streamUrl, previous: nil, current: episode.title, next: episode.author)
    }
    
    /// Lines rolling like a picker wheel: the past one tilts back and fades,
    /// the current one is bold, the next one waits in grey.
    private var lineWheel: some View {
        let lines = wheelLines
        return Button {
            toggleTranscript()
        } label: {
            VStack(spacing: 6) {
                Text(lines.previous ?? " ")
                    .font(rounded(18))
                    .foregroundStyle(Self.ink.opacity(0.16))
                    .lineLimit(1)
                    .rotation3DEffect(.degrees(42), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.45)
                
                Text(lines.current)
                    .font(rounded(23, .semibold))
                    .foregroundStyle(Self.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                
                Text(lines.next ?? " ")
                    .font(rounded(19))
                    .foregroundStyle(Self.ink.opacity(0.38))
                    .lineLimit(1)
                    .rotation3DEffect(.degrees(-24), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.45)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .id(lines.id)
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(height: 132)
        .clipped()
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: lines.id)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lines.current)
        .accessibilityHint("Opens the transcript")
    }
    
    /// Bookmark and transcript: small and quiet, out of the main row.
    private var secondaryActions: some View {
        HStack {
            bookmarkButton
            Spacer()
            transcriptButton
        }
        .foregroundStyle(Self.ink.opacity(0.55))
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
        .accessibilityLabel("Back to the player")
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
        HStack(alignment: .center) {
            Button {
                playerManager.collapse()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Minimize player")

            Spacer()

            // Time left, floating on the cover.
            Text(viewModel.remainingTimeText)
                .font(rounded(20, .semibold))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(.ultraThinMaterial, in: Capsule())
                .opacity(viewModel.remainingTimeText.isEmpty ? 0 : 1)
                .accessibilityLabel("Time remaining \(viewModel.remainingTimeText)")
        }
        .foregroundStyle(Self.ink)
        .padding(.top, 54)
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
                    .fill(Self.ink.opacity(0.08))
                
                Capsule()
                    .fill(Self.accent)
                    .frame(width: geo.size.width * CGFloat(viewModel.progress))
            }
            .frame(height: 4)
            .frame(maxHeight: .infinity)
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
        .frame(height: 24) // taller touch area than the 4pt line
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(viewModel.progress * 100)) percent")
    }
    
    private var progressLabels: some View {
        HStack {
            Text(viewModel.currentTimeText)
            Spacer()
            Text("-\(viewModel.remainingTimeText)")
        }
        .font(rounded(12))
        .monospacedDigit()
        .foregroundStyle(Self.ink.opacity(0.5))
    }
    
    // MARK: - Controls
    
    /// −15 · lavender play/pause · +15, nothing else in the main row.
    private var controlsSection: some View {
        HStack(spacing: 40) {
            seekBackwardButton
            playPauseButton
            seekForwardButton
        }
        .frame(maxWidth: .infinity)
    }
    
    private var bookmarkButton: some View {
        Button {
            actionViewModel.toggleBookmark()
        } label: {
            Image(systemName: actionViewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: 19, weight: .regular))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(actionViewModel.isBookmarked ? Text("Remove from saved") : Text("Save episode"))
    }
    
    private var seekBackwardButton: some View {
        Button {
            viewModel.seekBackward()
        } label: {
            Image(systemName: "gobackward.15")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Self.ink)
                .frame(width: 56, height: 56)
        }
        .accessibilityLabel("Rewind 15 seconds")
    }
    
    private var playPauseButton: some View {
        Button {
            viewModel.togglePlayPause()
        } label: {
            ZStack {
                Circle()
                    .fill(Self.accent)
                    .frame(width: 88, height: 88)
                
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(Self.ink)
                    .contentTransition(.symbolEffect(.replace))
                    .offset(x: viewModel.isPlaying ? 0 : 3)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.isPlaying ? Text("Pause") : Text("Play"))
    }
    
    private var seekForwardButton: some View {
        Button {
            viewModel.seekForward()
        } label: {
            Image(systemName: "goforward.15")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(Self.ink)
                .frame(width: 56, height: 56)
        }
        .accessibilityLabel("Skip forward 15 seconds")
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
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(transcriptAccessibilityLabel)
    }
    
    private var transcriptIcon: String {
        if transcript.error != nil { return "exclamationmark.bubble" }
        return transcript.segments.isEmpty ? "captions.bubble" : "captions.bubble.fill"
    }
    
    private var transcriptAccessibilityLabel: String {
        if mode == .transcript { return String(localized: "Close transcript") }
        if transcript.isLoading { return String(localized: "Preparing transcript") }
        if transcript.error != nil { return String(localized: "Retry transcript") }
        return String(localized: "Transcript")
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
