//
//  PlayerView.swift
//  Podcast
//

import SwiftUI

struct PlayerView: View {
    
    let episode: Episode
    @State private var mode: PlayerMode = .normal
    /// Which tab is open under the cover.
    @State private var tab: PlayerTab = .player
    /// From the show notes; empty = no Chapters tab.
    @State private var chapters: [EpisodeChapter]
    @Namespace private var tabNamespace
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
        _chapters = State(initialValue: EpisodeChapter.parse(showNotes: episode.chapterSource))
    }
    
    // MARK: - Style (soft white, near-black ink, lavender accent)
    
    private static let paper = AppColor.paper
    private static let ink = AppColor.ink
    private static let accent = AppColor.lavender
    
    
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
            chapters = EpisodeChapter.parse(showNotes: episode.chapterSource)
            tab = .player
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
                tabPicker
                    .padding(.top, 2)

                Group {
                    switch tab {
                    case .player: playerTab
                    case .text: textTab
                    case .chapters: chaptersTab
                    }
                }
                .frame(maxHeight: .infinity)
                .transition(.opacity)

                // Chapters: no buttons, just how far along it is.
                // Text: nothing at all, the transcript gets the whole space.
                if tab == .chapters {
                    thinProgress
                        .padding(.bottom, 24)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 28)
            .animation(AppAnimation.playerTab, value: tab)
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
            // Fades the cover itself out (a mask, not a paper-colored overlay):
            // with an overlay, the cover's last row of pixels could peek out
            // under it while the sheet slides in at fractional positions,
            // showing up as a thin light line above the tabs.
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

    // MARK: - Tabs

    private var availableTabs: [PlayerTab] {
        PlayerTab.available(hasChapters: !chapters.isEmpty)
    }

    /// Player · Text · Chapters as plain words; a thin line slides under the
    /// chosen one (editorial, like a magazine's sections).
    private var tabPicker: some View {
        HStack(spacing: 26) {
            ForEach(availableTabs, id: \.self) { item in
                tabButton(item)
            }
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.selection, trigger: tab)
    }

    private func tabButton(_ item: PlayerTab) -> some View {
        let isOn = tab == item
        let textColor: Color = isOn ? Self.ink : Self.ink.opacity(0.45)
        return Button {
            tab = item
        } label: {
            Text(item.title)
                .font(AppFont.label)
                .foregroundStyle(textColor)
                .padding(.vertical, 8)
                .overlay(alignment: .bottom) {
                    if isOn {
                        Capsule()
                            .fill(Self.ink)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "tab", in: tabNamespace)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    // MARK: - Player tab

    private var playerTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 12)
            VStack(alignment: .leading, spacing: 12) {
                Text(episode.title)
                    .font(AppFont.title)
                    .foregroundStyle(Self.ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                byline
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            progressSection
                .padding(.top, 20)

            controlsSection
                .padding(.top, 14)

            actionsRow
                .padding(.top, 14)
            Spacer(minLength: 12)
        }
    }

    /// Small round artwork, "By author" and "7 hours ago · 35 min".
    private var byline: some View {
        HStack(spacing: 10) {
            Color.clear
                .frame(width: 28, height: 28)
                .overlay { PodcastImage(source: episode.imageUrl) }
                .clipShape(Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("By \(episode.author)")
                    .font(AppFont.captionStrong)
                    .foregroundStyle(Self.ink)
                    .lineLimit(1)
                HStack(spacing: 0) {
                    Text(episode.pubDate, format: .relative(presentation: .numeric, unitsStyle: .wide))
                    Text(verbatim: " · \(episode.durationDisplayText)")
                }
                .font(AppFont.caption)
                .foregroundStyle(Self.ink.opacity(0.5))
                .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Thin icons with their word, like an article's share bar.
    private var actionsRow: some View {
        HStack(spacing: 22) {
            Button {
                actionViewModel.toggleBookmark()
            } label: {
                Label(actionViewModel.isBookmarked ? "Saved" : "Save",
                      systemImage: actionViewModel.isBookmarked ? "bookmark.fill" : "bookmark")
            }

            Button {
                switch actionViewModel.downloadState {
                case .idle, .failed: actionViewModel.download()
                default: break
                }
            } label: {
                Label(downloadTitle, systemImage: downloadIcon)
            }

            Spacer(minLength: 0)

            if let url = URL(string: episode.streamUrl) {
                ShareLink(item: url, subject: Text(episode.title)) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Share")
            }
        }
        .buttonStyle(.plain)
        .font(AppFont.footnote)
        .foregroundStyle(Self.ink.opacity(0.55))
        .frame(height: 44)
    }

    private var downloadTitle: LocalizedStringKey {
        switch actionViewModel.downloadState {
        case .downloaded: "Downloaded"
        case .downloading, .waiting: "Downloading"
        default: "Download"
        }
    }

    private var downloadIcon: String {
        switch actionViewModel.downloadState {
        case .downloaded: "checkmark.circle"
        case .downloading, .waiting: "arrow.down.circle.dotted"
        default: "arrow.down"
        }
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
    /// a quote (italic, with a lavender “).
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

    // MARK: - Chapters tab

    /// The chapter being played: the last one that already started.
    private var currentChapter: EpisodeChapter? {
        let now = viewModel.currentPlaybackSeconds
        return chapters.last(where: { $0.start <= now })
    }

    private var chaptersTab: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(chapters) { chapter in
                    chapterRow(chapter)
                }
            }
            .padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
    }

    private func chapterRow(_ chapter: EpisodeChapter) -> some View {
        let isCurrent = currentChapter?.id == chapter.id
        let isPast = !isCurrent && chapter.start < viewModel.currentPlaybackSeconds
        let dotColor: Color = isCurrent ? Self.accent : Color.clear
        let titleColor: Color = isCurrent ? AppColor.lavenderInk : Self.ink.opacity(isPast ? 0.45 : 1)
        let titleWeight: Font.Weight = isCurrent ? .bold : .medium
        return Button {
            viewModel.seek(toSeconds: chapter.start)
        } label: {
            HStack(spacing: 14) {
                Text(AVPlayerViewModel.shortTime(chapter.start))
                    .font(AppFont.footnote)
                    .monospacedDigit()
                    .foregroundStyle(isCurrent ? AppColor.lavenderInk : Self.ink.opacity(0.45))
                    .frame(width: 52, alignment: .leading)
                Text(chapter.title)
                    .font(AppFont.itemTitle.weight(titleWeight))
                    .foregroundStyle(titleColor)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isCurrent {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle().fill(Self.ink.opacity(0.06)).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    // MARK: - Tab pieces

    /// A thin, read-only progress line for Text and Chapters.
    private var thinProgress: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Self.ink.opacity(0.08))
                Capsule()
                    .fill(Self.accent)
                    .frame(width: geo.size.width * CGFloat(viewModel.progress))
            }
        }
        .frame(height: 3)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(viewModel.progress * 100)) percent")
    }

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
                    .foregroundStyle(AppColor.lavenderInk)
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
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .frame(height: 44)
                .background(Capsule().fill(AppColor.lavenderInk))
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
                .font(.system(.title3, weight: .semibold))
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
    
    /// −15 · lavender play/pause · +15, nothing else in the main row.
    private var controlsSection: some View {
        HStack(spacing: 40) {
            seekBackwardButton
            playPauseButton
            seekForwardButton
        }
        .frame(maxWidth: .infinity)
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
            playerManager.togglePlayPause()
        } label: {
            ZStack {
                Circle()
                    .fill(Self.accent)
                    .frame(width: 76, height: 76)
                
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(AppColor.Text.onPastel)
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

#Preview {
    PlayerView(episode: .mock)
        .environment(\.playerManager, .preview)
}
