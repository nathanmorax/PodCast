//
//  PlayerManager.swift
//  Podcast
//
//  Created by Jonathan Mora on 23/03/26.
//
import SwiftUI
import Observation

@Observable
final class PlayerManager {
    
    static let shared = PlayerManager()
    private init() {}
    
    var currentEpisode: Episode?
    var presentation: PlayerPresentation = .hidden
    
    let viewModel   = AVPlayerViewModel()
    let transcript  = TranscriptViewModel()
    
    enum PlayerPresentation {
        case hidden
        case mini
        case expanded
    }
    
    // MARK: - Public API
    
    func play(_ episode: Episode, presentation: PlayerPresentation = .expanded) {
        currentEpisode = episode
        guard let url = URL(string: episode.streamUrl) else { return }
        
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
