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
    
    var episode: Episode
    @State private var mode: PlayerMode = .normal
    @State private var showControls: Bool = true
    @State private var hideControlsTask: Task<Void, Never>?
    

    
    private var viewModel: AVPlayerViewModel {
        PlayerManager.shared.viewModel
    }
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                if mode == .normal {
                    bigHeader
                } else {
                    CompactHeader(episode: episode, playerMode: $mode)
                }
                
                if mode == .normal {
                    normalPanel
                } else {
                    transcriptPanel
                }
            }
            .edgesIgnoringSafeArea(.top)
        }
        .gesture(dismissGesture)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: mode)
    }
    
    // MARK: - Modo NORMAL
    
    private var bigHeader: some View {
        PodcastImage(source: episode.imageUrl)
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height * 0.5)
            .clipped()
    }
    
    private var normalPanel: some View {
        VStack(spacing: 24) {
            descriptionEpisode
                .padding(.top, 32)
            
            waveForm
            
            buttonAction
            
            lyricsPreview
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
    
    // MARK: - Modo TRANSCRIPT
    

    
    private var transcriptPanel: some View {
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
    
    private var compactControls: some View {
        VStack(spacing: 12) {
            ProgressView(value: viewModel.progress)
                .tint(AppColor.lavender)
                .padding(.horizontal, 24)
            
            HStack {
                Text(viewModel.currentTimeText)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
                Spacer()
                Text(viewModel.durationText)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 24)
            
            buttonAction
        }
    }
    
    // MARK: - Componentes compartidos
    
    private var descriptionEpisode: some View {
        VStack(spacing: 12) {
            Text(episode.title)
                .font(.system(size: 29, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .foregroundStyle(.black)
                .lineLimit(4)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
            
            Text(episode.author)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.gray)
        }
    }
    
    private var waveForm: some View {
        VStack(spacing: 8) {
            WaveformBars(
                progress: viewModel.progress,
                barCount: 60
            ) { percentage in
                viewModel.seek(to: percentage)
            }
            .frame(height: 40)
            .padding(.horizontal, 42)
            
            HStack {
                Text(viewModel.currentTimeText)
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                
                Spacer()
                
                Text(viewModel.durationText)
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 42)
        }
    }
    
    private var buttonAction: some View {
        HStack(spacing: 48) {
            AppButton(
                style: .icon,
                tone: .brand,
                size: .compact,
                icon: .only(Image(systemName: "gobackward.15")),
                title: "Rewind"
            ) {
                viewModel.seekBackward()
            }
            
            AppButton(
                style: .icon,
                tone: .brand,
                size: .regular,
                icon: .toggle(
                    selected: Image(systemName: "pause.fill"),
                    unselected: Image(systemName: "play.fill")
                ),
                title: "Play/Pause",
                isSelected: viewModel.isPlaying
            ) {
                viewModel.togglePlayPause()
            }
            
            AppButton(
                style: .icon,
                tone: .brand,
                size: .compact,
                icon: .only(Image(systemName: "goforward.15")),
                title: "Forward"
            ) {
                viewModel.seekForward()
            }
        }
        .padding(.vertical, 8)
    }
    
    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                if value.translation.height > 100 && mode == .normal {
                    PlayerManager.shared.collapse()
                }
            }
    }
    
    // MARK: - Lyrics preview (modo normal)
    
    private var lyricsPreview: some View {
        VStack(spacing: 12) {
            if viewModel.isLoadingTranscript {
                VStack(spacing: 8) {
                    ProgressView()
                    Text(viewModel.transcriptProgress)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                .padding()
                
            } else if let error = viewModel.transcriptError {
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
                
            } else if viewModel.transcriptSegments.isEmpty {
                Button {
                    Task { await runTranscription() }
                } label: {
                    Label("Generar transcripción", systemImage: "text.bubble")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Capsule().fill(AppColor.lavender))
                }
                .padding(.top, 8)
                
            } else {
                Button {
                    mode = .transcript
                } label: {
                    VStack(spacing: 6) {
                        if let current = viewModel.currentSegment {
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
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
    
    // MARK: - Transcript scroll
    
    private var transcriptScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(viewModel.transcriptSegments) { segment in
                        Text(segment.text)
                            .font(.system(
                                size: 19,
                                weight: viewModel.currentSegment?.id == segment.id ? .semibold : .regular
                            ))
                            .foregroundStyle(
                                viewModel.currentSegment?.id == segment.id
                                ? .black
                                : .gray.opacity(0.4)
                            )
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(segment.id)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.currentSegment?.id == segment.id)
                            .onTapGesture {
                                seekToSegment(segment)
                                showControlsTemporarily()
                            }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .padding(.bottom, 40)
            }
            .onChange(of: viewModel.currentSegment?.id) { _, newId in
                guard let newId else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    proxy.scrollTo(newId, anchor: .center)
                }
            }
            .onAppear {
                if let id = viewModel.currentSegment?.id {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - Acciones
    
    private func runTranscription() async {
        print("🚀 Botón presionado, llamando generateTranscript...")
        if #available(iOS 26.0, *) {
            await viewModel.generateTranscript(
                for: episode.streamUrl,
                episodeId: episode.streamUrl
            )
        }
    }
    
    private func seekToSegment(_ segment: LocalTranscriptSegment) {
        guard let last = viewModel.transcriptSegments.last,
              last.endTime > 0 else { return }
        let percentage = Float(segment.startTime / last.endTime)
        viewModel.seek(to: percentage)
    }
    
    // MARK: - Auto-hide controls
    
    private func showControlsTemporarily() {
        withAnimation {
            showControls = true
        }
        scheduleHideControls()
    }
    
    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(3))
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                withAnimation {
                    showControls = false
                }
            }
        }
    }
}

//#Preview {
//    PlayerView(episode: .mock)
//}
