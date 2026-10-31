//
//  PlayerView.swift
//  Podcast
//

import SwiftUI

struct PlayerView: View {
    
    let episode: Episode
    @State private var mode: PlayerMode = .normal
    /// The transcript, as a sheet over the player.
    @State private var showsTranscript = false
    @State private var sleepTimer = SleepTimer.shared
    /// How far the finger has pulled the player down (follows it 1:1).
    @State private var dismissOffset: CGFloat = 0
    /// Set on the first movement of a drag: only a vertical drag pulls the
    /// player down; a sideways one (scrubbing, the line wheel) is left alone.
    @State private var dragAxis: Axis?
    /// Where the finger is on the progress bar while scrubbing (nil otherwise).
    @State private var scrubProgress: Float?
    
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
    
    // MARK: - Style (paper, ink, mustard accent)
    
    private static let paper = AppColor.paper
    private static let ink = AppColor.ink
    private static let accent = AppColor.accent
    
    
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
        // Pulled down: the sheet follows the finger and rounds its corners,
        // like Apple Podcasts. The app behind shows through.
        .clipShape(RoundedRectangle(cornerRadius: min(dismissOffset / 3, 44), style: .continuous))
        .offset(y: dismissOffset)
        .gesture(dismissGesture)
        .animation(AppAnimation.transcriptMode, value: mode)
        .onChange(of: viewModel.progress) { _, _ in
            transcript.updateCurrentSegment(playbackSeconds: viewModel.currentPlaybackSeconds)
        }
        // Opened again while it was still sliding down (taps on the mini
        // player during the close): SwiftUI reverses the exit and keeps this
        // same view, offset included, so it stopped halfway. Start from the top.
        .onChange(of: playerManager.presentation) { _, presentation in
            guard presentation == .expanded, dismissOffset != 0 else { return }
            withAnimation(AppAnimation.playerPresentation) { dismissOffset = 0 }
            dragAxis = nil
        }
        .onChange(of: episode.streamUrl) { _, _ in
            // @State ignores new init values, so rebuild the VM when the episode changes.
            actionViewModel = EpisodeActionViewModel(episode: episode)
            showsTranscript = false
        }
        .sheet(isPresented: $showsTranscript) { transcriptSheet }
    }
    
    // MARK: - Normal View

    /// The cover edge to edge at the top, under the status bar, filling the
    /// space the rest leaves and fading into the page (⌄ and ••• float on
    /// it); then the date, the title and the show (in the accent), centered;
    /// a thick bar; time · −15 · ❚❚ · +30 · time left; and at the bottom a
    /// tray with share · speed · save · sleep · transcript. Pull down
    /// anywhere to close.
    private var normalView: some View {
        VStack(spacing: 0) {
            heroArtwork
                .overlay(alignment: .top) {
                    topBar
                        .padding(.horizontal, 16)
                }
                .ignoresSafeArea(.container, edges: .top)

            info
                .padding(.horizontal, 28)
                .padding(.top, 8)

            progressBar
                .padding(.horizontal, 28)
                .padding(.top, 28)

            controlsSection
                .padding(.horizontal, 28)
                .padding(.top, 10)

            bottomBar
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Artwork

    private var hasArtwork: Bool {
        !(episode.imageUrl ?? "").isEmpty
    }

    /// Full width, from the very top down to the title: it takes all the
    /// room the rest leaves (the rest keeps its own, so nothing gets
    /// covered or squeezed), with no empty gaps in between. It fades into
    /// the page at the bottom (a mask, so no line of the cover peeks out
    /// while the sheet slides).
    private var heroArtwork: some View {
        Color.clear
            .frame(maxWidth: .infinity, minHeight: 180, maxHeight: .infinity)
            .layoutPriority(-1)
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
            // Keeps the status bar and the floating buttons readable.
            .overlay(alignment: .top) {
                LinearGradient(colors: [.black.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 140)
            }
            .mask {
                VStack(spacing: 0) {
                    Rectangle()
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 70)
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }

    // MARK: - Date, title, show

    private var info: some View {
        VStack(spacing: 8) {
            Text(episode.pubDate, format: .dateTime.day().month(.wide).year())
                .font(.footnote)
                .foregroundStyle(Self.ink.opacity(0.55))
            Text(episode.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Self.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
            if !episode.author.isEmpty {
                Text(episode.author)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColor.Accent.strong)
                    .lineLimit(1)
                    .padding(.top, 4)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom tray

    /// Share · speed · save · sleep · transcript, spread in a rounded tray.
    private var bottomBar: some View {
        HStack(spacing: 0) {
            if let url = URL(string: episode.streamUrl) {
                ShareLink(item: url, subject: Text(episode.title)) {
                    trayGlyph("square.and.arrow.up")
                }
                .accessibilityLabel("Share")
            }
            Spacer(minLength: 0)
            speedMenu
            Spacer(minLength: 0)
            Button {
                actionViewModel.toggleBookmark()
            } label: {
                trayGlyph(actionViewModel.isBookmarked ? "bookmark.fill" : "bookmark",
                          color: actionViewModel.isBookmarked ? AppColor.Accent.strong : Self.ink)
            }
            .sensoryFeedback(.success, trigger: actionViewModel.isBookmarked) { _, saved in saved }
            .accessibilityLabel(actionViewModel.isBookmarked ? Text("Saved") : Text("Save"))
            Spacer(minLength: 0)
            sleepMenu
            Spacer(minLength: 0)
            Button {
                showsTranscript = true
            } label: {
                trayGlyph("text.quote")
            }
            .accessibilityLabel("Transcript")
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(AppColor.Surface.muted, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func trayGlyph(_ systemName: String, color: Color = AppColor.ink) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 21, weight: .regular))
            .contentTransition(.symbolEffect(.replace))
            .foregroundStyle(color)
            .frame(width: 48, height: 48)
            .contentShape(Rectangle())
    }

    // MARK: - Transcript sheet

    private var transcriptSheet: some View {
        NavigationStack {
            textTab
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Self.paper)
                .navigationTitle("Transcript")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showsTranscript = false }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Text tab

    @ViewBuilder
    private var textTab: some View {
        if !transcript.segments.isEmpty {
            transcriptList
        } else if transcript.isLoading {
            TranscribingIndicator()
        } else if transcript.error != nil {
            tabMessage(
                icon: "exclamationmark.bubble",
                title: Text("Couldn't make the transcript"),
                detail: Text(verbatim: transcript.error ?? "")
            ) {
                tabActionButton("Try again") { Task { await runTranscription() } }
            }
        } else {
            tabMessage(
                icon: "captions.bubble",
                title: Text("Transcribe this episode"),
                detail: Text("It's made on your iPhone and can take a few minutes.")
            ) {
                tabActionButton("Transcribe") { Task { await runTranscription() } }
            }
        }
    }

    /// Every line; the one being said is dark and stays in view. Tap = jump.
    private var transcriptList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(transcript.segments) { segment in
                        transcriptRow(segment)
                            .id(segment.id)
                    }
                }
                .padding(.vertical, 18)
            }
            .scrollIndicators(.hidden)
            // Lines fade in and out at the edges instead of being cut.
            .mask(Self.edgeFade)
            .overlay(alignment: .topTrailing) { fullScreenButton }
            .onAppear {
                if let id = transcript.currentSegment?.id { proxy.scrollTo(id, anchor: .center) }
            }
            .onChange(of: transcript.currentSegment?.id) { _, id in
                guard let id else { return }
                withAnimation(AppAnimation.subtitleLine) { proxy.scrollTo(id, anchor: .center) }
            }
        }
    }

    /// Read like an article: every line in serif; the one being said becomes
    /// a quote (italic, with an accent “).
    private func transcriptRow(_ segment: LocalTranscriptSegment) -> some View {
        let isCurrent = transcript.currentSegment?.id == segment.id
        return Button {
            viewModel.seek(toSeconds: segment.startTime)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                if isCurrent {
                    Text(verbatim: "“")
                        .font(.system(size: 44, design: .serif))
                        .foregroundStyle(Self.accent)
                        .frame(height: 30, alignment: .top)
                        .accessibilityHidden(true)
                        .transition(.opacity)
                }
                Text(segment.text)
                    .font(isCurrent ? AppFont.quote : AppFont.itemTitle.weight(.regular))
                    .foregroundStyle(Self.ink.opacity(isCurrent ? 1 : 0.38))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .animation(AppAnimation.subtitleLine, value: isCurrent)
    }

    /// Lines fade in and out at the top and bottom edges instead of being cut.
    private static let edgeFade = LinearGradient(
        stops: [
            Gradient.Stop(color: Color.clear, location: 0),
            Gradient.Stop(color: Color.black, location: 0.08),
            Gradient.Stop(color: Color.black, location: 0.85),
            Gradient.Stop(color: Color.clear, location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Opens the full-screen subtitles (TranscriptSubtitleView).
    private var fullScreenButton: some View {
        Button {
            // Closes the sheet, then the subtitles take the whole player.
            showsTranscript = false
            mode = .transcript
        } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Self.ink.opacity(0.55))
                .frame(width: 32, height: 32)
                .background(Circle().fill(Self.ink.opacity(0.06)))
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
        .accessibilityLabel("Full screen")
    }

    // MARK: - Tab pieces

    private func tabMessage<Action: View>(
        icon: String?,
        title: Text,
        detail: Text,
        @ViewBuilder action: () -> Action
    ) -> some View {
        VStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(AppColor.accentInk)
                    .accessibilityHidden(true)
            }
            title
                .font(AppFont.sectionTitle)
                .foregroundStyle(Self.ink)
            detail
                .font(AppFont.body)
                .foregroundStyle(Self.ink.opacity(0.5))
                .multilineTextAlignment(.center)
            action()
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
    }

    private func tabActionButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.label)
                .foregroundStyle(AppColor.Text.inverse)
                .padding(.horizontal, 22)
                .frame(height: 44)
                .background(Capsule().fill(AppColor.accentInk))
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

    /// Subtitles: the sentence being said, the one before it faint above,
    /// and a pause pill. See TranscriptSubtitleView.
    private var transcriptView: some View {
        TranscriptSubtitleView(
            previous: transcript.previousSegment?.text,
            current: transcript.displayedSegment?.text,
            lineID: transcript.displayedSegment?.id,
            isPlaying: viewModel.isPlaying,
            timeText: "\(viewModel.currentTimeText) / \(viewModel.durationText)",
            onTogglePlay: { playerManager.togglePlayPause() },
            onClose: { mode = .normal }
        )
    }

    // MARK: - Top Bar

    /// ⌄ and ••• (save, download, share), in frosted circles on the cover.
    private var topBar: some View {
        HStack {
            Button {
                playerManager.collapse()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Self.ink)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Minimize player")

            Spacer()

            Menu {
                EpisodeActionsMenuItems(actions: actionViewModel)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Self.ink)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("More")
        }
        // Below the status bar (the cover runs under it).
        .padding(.top, 58)
    }

    // MARK: - Progress
    
    /// What the bar shows: the finger while scrubbing, the player otherwise.
    private var shownProgress: Float {
        scrubProgress ?? viewModel.progress
    }

    /// Scrubbing follows the finger 1:1 and seeks ONCE, on release.
    /// Before, every finger movement called seek(): each one cancelled the
    /// previous seek on the stream, and the bar only moved when the player
    /// reported a new time, so it advanced in jumps.
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Self.ink.opacity(0.1))

                Capsule()
                    .fill(AppColor.Accent.strong)
                    .frame(width: geo.size.width * CGFloat(shownProgress))
            }
            // Grows while held, like the system scrubbers.
            .frame(height: scrubProgress == nil ? 6 : 12)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // Use the bar's real width, not the screen's.
                        guard geo.size.width > 0 else { return }
                        let percentage = Float(value.location.x / geo.size.width)
                        scrubProgress = min(max(percentage, 0), 1)
                    }
                    .onEnded { _ in
                        if let target = scrubProgress {
                            viewModel.seek(to: target)
                        }
                        scrubProgress = nil
                    }
            )
            .animation(AppAnimation.selection, value: scrubProgress == nil)
        }
        .frame(height: 28) // taller touch area than the 6 pt bar
        .sensoryFeedback(.selection, trigger: scrubProgress == nil)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(viewModel.progress * 100)) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: viewModel.seekForward()
            case .decrement: viewModel.seekBackward()
            @unknown default: break
            }
        }
    }
    
    /// Where it is (the finger's spot while scrubbing).
    private var elapsedLabel: some View {
        Text(scrubProgress.map(viewModel.timeText(at:)) ?? viewModel.currentTimeText)
            .font(.footnote)
            .monospacedDigit()
            .foregroundStyle(Self.ink.opacity(0.6))
            .frame(width: 56, alignment: .leading)
    }

    /// Time left.
    private var remainingLabel: some View {
        Text(verbatim: remainingText)
            .font(.footnote)
            .monospacedDigit()
            .foregroundStyle(Self.ink.opacity(0.6))
            .frame(width: 56, alignment: .trailing)
    }

    /// "−43:20"; before the player knows the length (not loaded yet), the
    /// episode's own length.
    private var remainingText: String {
        if let scrubProgress { return "−" + viewModel.remainingText(at: scrubProgress) }
        let left = viewModel.remainingTimeText
        return left.isEmpty ? episode.durationDisplayText : "−" + left
    }

    // MARK: - Controls

    /// time · −15 · ❚❚ · +30 · time left.
    private var controlsSection: some View {
        HStack(spacing: 0) {
            elapsedLabel
            Spacer(minLength: 0)
            seekBackwardButton
            Spacer(minLength: 0)
            playPauseButton
            Spacer(minLength: 0)
            seekForwardButton
            Spacer(minLength: 0)
            remainingLabel
        }
    }

    private var speedMenu: some View {
        Menu {
            Picker("Speed", selection: Binding(
                get: { viewModel.playbackRate },
                set: { viewModel.setPlaybackRate($0) }
            )) {
                ForEach(AVPlayerViewModel.rates, id: \.self) { rate in
                    Text(verbatim: AVPlayerViewModel.rateText(rate)).tag(rate)
                }
            }
        } label: {
            Text(verbatim: AVPlayerViewModel.rateText(viewModel.playbackRate))
                .font(.system(.title3, weight: .regular))
                .monospacedDigit()
                .foregroundStyle(viewModel.playbackRate == 1 ? Self.ink : AppColor.Accent.strong)
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Speed")
        .accessibilityValue(Text(verbatim: AVPlayerViewModel.rateText(viewModel.playbackRate)))
    }

    private var sleepMenu: some View {
        Menu {
            if sleepTimer.isActive {
                Button("Turn off timer", systemImage: "moon.zzz") { sleepTimer.cancel() }
                Divider()
            }
            ForEach(SleepTimer.minuteOptions, id: \.self) { minutes in
                Button("\(minutes) min") { startSleep(.minutes(minutes)) }
            }
            Button("End of episode") { startSleep(.endOfEpisode) }
        } label: {
            Image(systemName: sleepTimer.isActive ? "moon.fill" : "moon")
                .font(.system(size: 21, weight: .regular))
                .foregroundStyle(sleepTimer.isActive ? AppColor.Accent.strong : Self.ink)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        } primaryAction: {
            // A tap turns it off when it's on; the menu opens otherwise
            // (touch and hold always opens it).
            if sleepTimer.isActive { sleepTimer.cancel() }
        }
        .accessibilityLabel("Sleep timer")
        .accessibilityValue(sleepValue)
    }

    private var sleepValue: Text {
        guard let endsAt = sleepTimer.endsAt else { return Text("Off") }
        return Text("Pauses at \(endsAt.formatted(date: .omitted, time: .shortened))")
    }

    private func startSleep(_ option: SleepTimer.Option) {
        let remaining = max(viewModel.durationSeconds - viewModel.currentPlaybackSeconds, 0)
        sleepTimer.start(option, remaining: remaining, rate: viewModel.playbackRate) {
            let manager = PlayerManager.shared
            if manager.viewModel.isPlaying { manager.togglePlayPause() }
        }
    }

    private var seekBackwardButton: some View {
        Button {
            viewModel.seekBackward()
        } label: {
            Image(systemName: "gobackward.15")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(Self.ink)
                .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Rewind 15 seconds")
    }

    /// ▶ / ❚❚ in a soft round button.
    private var playPauseButton: some View {
        Button {
            playerManager.togglePlayPause()
        } label: {
            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Self.ink)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 36, height: 36)
                .offset(x: viewModel.isPlaying ? 0 : 2)
                .frame(width: 80, height: 80)
                .background(AppColor.Surface.muted, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.isPlaying ? Text("Pause") : Text("Play"))
    }

    private var seekForwardButton: some View {
        Button {
            viewModel.skipForward30()
        } label: {
            Image(systemName: "goforward.30")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(Self.ink)
                .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Skip forward 30 seconds")
    }

    // MARK: - Helpers
    
    /// Interactive close: the player moves with the finger. Let go far enough
    /// (or fast enough) and it keeps going down; otherwise it springs back.
    /// Before, the gesture only acted on release, so it jumped closed at once.
    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                guard mode == .normal else { return }
                if dragAxis == nil {
                    dragAxis = abs(value.translation.height) > abs(value.translation.width) ? .vertical : .horizontal
                }
                guard dragAxis == .vertical else { return }
                // Down 1:1; up only a little, with resistance.
                let y = value.translation.height
                dismissOffset = y >= 0 ? y : -sqrt(-y) * 2
            }
            .onEnded { value in
                defer { dragAxis = nil }
                guard mode == .normal, dragAxis == .vertical else { return }
                if PlayerDismissRule.shouldClose(
                    translation: value.translation.height,
                    predictedEnd: value.predictedEndTranslation.height
                ) {
                    // The sheet leaves from where it is now (its offset stays
                    // while the transition moves it the rest of the way).
                    playerManager.collapse()
                } else {
                    withAnimation(AppAnimation.gestureRelease) { dismissOffset = 0 }
                }
            }
    }
}
