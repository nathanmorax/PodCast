//
//  PlayerManager.swift
//  Podcast
//
//  Created by Jonathan Mora on 23/03/26.
//
import SwiftUI
import Observation

@MainActor
@Observable
final class PlayerManager {
    
    static let shared = PlayerManager()

    @ObservationIgnored
    private let downloadManager: DownloadManager

    @ObservationIgnored
    private let recentlyPlayed: RecentlyPlayedManager

    init(
        downloadManager: DownloadManager = .shared,
        recentlyPlayed: RecentlyPlayedManager = .shared,
        viewModel: AVPlayerViewModel = AVPlayerViewModel()
    ) {
        self.downloadManager = downloadManager
        self.recentlyPlayed = recentlyPlayed
        self.viewModel = viewModel
    }
    
    var currentEpisode: Episode?
    var presentation: PlayerPresentation = .hidden
    
    let viewModel: AVPlayerViewModel
    let transcript  = TranscriptViewModel()
    
    enum PlayerPresentation {
        case hidden
        case mini
        case expanded
    }
    
    // MARK: - Public API
    
    func play(_ episode: Episode, presentation: PlayerPresentation = .expanded) {
        // Same episode that's already loaded: don't reload it from 0:00.
        // Just make sure it's playing and show the player.
        if currentEpisode?.streamUrl == episode.streamUrl {
            if !viewModel.isPlaying {
                viewModel.togglePlayPause()
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                self.presentation = presentation
            }
            return
        }
        
        // Save how far the listener got in the episode they're leaving,
        // then put the new one at the top of "recently played".
        if let previous = currentEpisode, previous.streamUrl != episode.streamUrl {
            recentlyPlayed.updateProgress(for: previous, progress: Double(viewModel.progress))
        }
        recentlyPlayed.record(episode)
        
        currentEpisode = episode
        
        let url: URL
        if let localURL = downloadManager.localURL(for: episode) {
            url = localURL
        } else {
            guard let remoteURL = URL(string: episode.streamUrl) else { return }
            url = remoteURL
        }
        
        transcript.reset()
        viewModel.playEpisode(url: url)
        transcript.loadIfCached(for: episode.streamUrl)
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            self.presentation = presentation
        }
    }
    
    func expand() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            presentation = .expanded
        }
    }
    
    func collapse() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            presentation = .mini
        }
    }
    
    func playOrToggle(_ episode: Episode, presentation: PlayerPresentation = .mini) {
        if currentEpisode?.streamUrl == episode.streamUrl {
            viewModel.togglePlayPause()
            return
        }
        
        play(episode, presentation: presentation)
    }
    
    func togglePlayPause() {
        viewModel.togglePlayPause()
    }
}
