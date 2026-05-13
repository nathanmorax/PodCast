//
//  PlayerManager.swift
//  Podcast
//
//  Created by Satori Tech 341 on 23/03/26.
//
import SwiftUI
import Observation

@Observable
final class PlayerManager {
    
    static let shared = PlayerManager()
    private init() {}
    
    var currentEpisode: Episode?
    var presentation: PlayerPresentation = .hidden
    
    let viewModel = AVPlayerViewModel()
    
    enum PlayerPresentation {
        case hidden
        case mini
        case expanded
    }
    
    // MARK: - Public API
    
    func play(_ episode: Episode) {
        currentEpisode = episode
        viewModel.playEpisode(episode)
        expand()
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
}
