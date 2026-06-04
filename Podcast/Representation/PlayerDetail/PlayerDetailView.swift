//
//  PlayerView.swift
//  Podcast
//

import SwiftUI

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
            
            if mode == .normal {
                normalView
            } else {
                transcriptView
            }
        }
        .gesture(dismissGesture)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: mode)
    }
    
    // MARK: - Normal View
    
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
            Spacer(minLength: 24)
            lyricsPreview  // <- aquí
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Transcript View
    
    // MARK: - Lyrics Preview
    
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
                        .background(Capsule().fill(Color.black))
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
        .padding(.top, 8)
    }
    
    // MARK: - Transcripción
    
    private func runTranscription() async {
        if #available(iOS 26.0, *) {
            await viewModel.generateTranscript(
                for: episode.streamUrl,
                episodeId: episode.streamUrl
            )
        }
    }
    
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
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            Text(formattedDate)
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
                        let geo = UIScreen.main.bounds.width - 48
                        let percentage = Float(value.location.x / geo)
                        viewModel.seek(to: min(max(percentage, 0), 1))
                    }
            )
            
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
    }
    
    // MARK: - Controls
    
    private var controlsSection: some View {
        HStack(alignment: .center) {
            Button {
                viewModel.toggleBookmark(for: episode)
                print("Episode:: ", episode.title)
            } label: {
                Image(systemName: viewModel.isBookMarked(episode) ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.black)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.6),
                               value: viewModel.isBookMarked(episode)
                    )
            }
            
            Spacer()
            
            Button {
                viewModel.seekBackward()
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(.black)
            }
            
            Spacer()
            
            Button {
                viewModel.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                        .offset(x: viewModel.isPlaying ? 0 : 2)
                }
            }
            
            Spacer()
            
            Button {
                viewModel.seekForward()
            } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(.black)
            }
            
            Spacer()
            
            Button {
                mode = .transcript
            } label: {
                Image(systemName: "captions.bubble")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.black)
            }
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
    
    // MARK: - Transcript Scroll
    
    private var transcriptScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
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
                .padding(.bottom, 120)
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
    
    // MARK: - Acciones
    
    private func seekToSegment(_ segment: LocalTranscriptSegment) {
        guard let last = viewModel.transcriptSegments.last,
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
