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
    
    // Estado observable
    var currentEpisode: Episode?
    var presentation: PlayerPresentation = .hidden
    
    // ViewModel del player (uno solo, compartido)
    let viewModel = AVPlayerViewModel()
    
    enum PlayerPresentation {
        case hidden       // no hay episodio
        case mini         // mini player abajo
        case expanded     // pantalla completa
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
