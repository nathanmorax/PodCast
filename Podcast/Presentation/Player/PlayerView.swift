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

    /// The cover edge to edge at the top (about half the screen, fading
    /// into the paper, ⌄ floating on it), then like a newspaper's audio
    /// player: the show and the day in small capitals, the title in serif,
    /// a thin bar, the controls (speed · −15 · ▶ · +30 · sleep), and under a
    /// rule the byline and the show notes to read while it plays. All of it
    /// scrolls; pulling the cover down closes the player.
    private var normalView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Only the cover pulls the player down: below it, a
                // vertical drag scrolls the notes.
                heroArtwork
                    .overlay(alignment: .top) {
                        topBar
                            .padding(.horizontal, 20)
                    }
                    .contentShape(Rectangle())
                    .gesture(dismissGesture)

                VStack(alignment: .leading, spacing: 0) {
                    showLine
                        .padding(.top, 8)
                    Text(episode.title)
                        .font(AppFont.title)
                        .foregroundStyle(Self.ink)
                        .lineLimit(4)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, 14)

                    utilityRow
                        .padding(.top, 8)

                    progressSection
                        .padding(.top, 14)

                    controlsSection
                        .padding(.top, 18)

                    Divider()
                        .padding(.top, 26)

                    notes
                        .padding(.top, 22)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .ignoresSafeArea(.container, edges: .top)
    }

    // MARK: - Artwork

    private var hasArtwork: Bool {
        !(episode.imageUrl ?? "").isEmpty
    }

    /// About half the screen, full width, under the status bar. It fades
    /// into the paper at the bottom so the text below sits on a clean page.
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
            // Fades the cover itself out (a mask, not a paper-colored overlay):
            // with an overlay, the cover's last row of pixels could peek out
            // under it while the sheet slides in at fractional positions.
            .mask {
                VStack(spacing: 0) {
                    Rectangle()
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 150)
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }

    // MARK: - Show, title, utility row

    /// [cover] THE SHOW · TODAY
    private var showLine: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(width: 32, height: 32)
                .overlay { PodcastImage(source: episode.imageUrl) }
                .clipped()
                .accessibilityHidden(true)
            Text(verbatim: "\(episode.author) · \(episode.pubDate.shortDayText())")
                .font(.footnote.weight(.medium))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(Self.ink.opacity(0.75))
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }

    /// Transcript on the left; ••• (save, download, share) on the right.
    private var utilityRow: some View {
        HStack {
            Button {
                showsTranscript = true
            } label: {
                Label("Transcript", systemImage: "quote.bubble")
                    .font(AppFont.label)
                    .foregroundStyle(Self.ink.opacity(0.7))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Menu {
                EpisodeActionsMenuItems(actions: actionViewModel)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Self.ink.opacity(0.7))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More")
        }
    }

    // MARK: - Notes

    /// "By author", then the show notes in serif, to read while listening.
    private var notes: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !episode.author.isEmpty {
                Text("By \(episode.author)")
                    .font(AppFont.body.weight(.medium))
                    .foregroundStyle(Self.ink)
            }
            let text = episode.chapterSource.plainTextFromHTML()
            if !text.isEmpty {
                Text(text)
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(Self.ink.opacity(0.9))
                    .lineSpacing(5)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    /// ⌄ on the cover, in a small frosted circle.
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
        }
        .padding(.top, 54)
    }

    // MARK: - Progress
    
    private var progressSection: some View {
        VStack(spacing: 6) {
            progressBar
            progressLabels
        }
    }
    
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
                    .fill(Self.ink.opacity(0.08))
                
                Capsule()
                    .fill(Self.accent)
                    .frame(width: geo.size.width * CGFloat(shownProgress))
            }
            // Grows while held, like the system scrubbers.
            .frame(height: scrubProgress == nil ? 4 : 10)
            // The knob: where it is, in ink.
            .overlay(alignment: .leading) {
                Circle()
                    .fill(Self.ink)
                    .frame(width: scrubProgress == nil ? 14 : 20)
                    .offset(x: geo.size.width * CGFloat(shownProgress) - (scrubProgress == nil ? 7 : 10))
                    .allowsHitTesting(false)
            }
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
        .frame(height: 24) // taller touch area than the 4pt line
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
    
    private var progressLabels: some View {
        HStack {
            Text(scrubProgress.map(viewModel.timeText(at:)) ?? viewModel.currentTimeText)
            Spacer()
            Text(verbatim: "−\(scrubProgress.map(viewModel.remainingText(at:)) ?? viewModel.remainingTimeText)")
        }
        .font(AppFont.caption)
        .monospacedDigit()
        .foregroundStyle(Self.ink.opacity(0.5))
    }
    
    // MARK: - Controls

    /// 1× · −15 · ▶ · +30 · ☾, spread across the width.
    private var controlsSection: some View {
        HStack(spacing: 0) {
            speedMenu
            Spacer(minLength: 0)
            seekBackwardButton
            Spacer(minLength: 0)
            playPauseButton
            Spacer(minLength: 0)
            seekForwardButton
            Spacer(minLength: 0)
            sleepMenu
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
                .font(.system(.title3, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(viewModel.playbackRate == 1 ? Self.ink : AppColor.Accent.strong)
                .frame(width: 52, height: 52)
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
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(sleepTimer.isActive ? AppColor.Accent.strong : Self.ink)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 52, height: 52)
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
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(Self.ink)
                .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Rewind 15 seconds")
    }

    /// A big ▶ / ❚❚ on its own, no circle behind it.
    private var playPauseButton: some View {
        Button {
            playerManager.togglePlayPause()
        } label: {
            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(Self.ink)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 64, height: 64)
                .offset(x: viewModel.isPlaying ? 0 : 3)
                .frame(width: 76, height: 76)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.isPlaying ? Text("Pause") : Text("Play"))
    }

    private var seekForwardButton: some View {
        Button {
            viewModel.skipForward30()
        } label: {
            Image(systemName: "goforward.30")
                .font(.system(size: 30, weight: .regular))
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
