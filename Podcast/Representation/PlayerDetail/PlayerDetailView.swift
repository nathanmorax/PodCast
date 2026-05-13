//
//  PlayerDetailView.swift
//  Podcast
//
//  Created by Xcaret Mora on 17/11/23.
//

import UIKit
import SwiftUI

struct PlayerView: View {
    
    var episode: Episode
    
    private var viewModel: AVPlayerViewModel {
        PlayerManager.shared.viewModel
    }
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                backgroundImageEpisode
                
                playerPanel
            }
            .edgesIgnoringSafeArea(.top)
            
            dismissButton
        }
        .gesture(dismissGesture)
        
    }
    
    private var dismissButton: some View {
        Button {
            PlayerManager.shared.collapse()
        } label: {
            Image(systemName: "chevron.down")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(.black.opacity(0.35)))
        }
        .padding(.top, 60)
        .padding(.leading, 20)
    }
    
    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                if value.translation.height > 100 {
                    PlayerManager.shared.collapse()
                }
            }
    }
    
    // MARK: - Imagen superior del episodio
    private var backgroundImageEpisode: some View {
        PodcastImage(source: episode.imageUrl)
            .frame(maxWidth: .infinity)
            .frame(height: UIScreen.main.bounds.height * 0.5)
            .clipped()
    }
    
    // MARK: - Panel blanco inferior
    private var playerPanel: some View {
        VStack(spacing: 24) {
            descriptionEpisode
                .padding(.top, 32)
            
            waveForm
            
            buttonAction
            
            lyrics
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
    
    // MARK: - Título y autor
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
    
    // MARK: - Waveform y tiempos
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
    
    // MARK: - Controles play/atrás/adelante
    private var buttonAction: some View {
        HStack(spacing: 48) {
            
            
            AppButton(
                style: .icon,
                tone: .brand, size: .compact,
                icon: .only(Image(systemName: "gobackward.15")),
                title: "redwind",
            ) {
                viewModel.seekBackward()
            }
            
            
            AppButton(
                style: .icon,
                tone: .brand, size: .regular,
                icon: .toggle(
                    selected: Image(systemName: "pause.fill"),
                    unselected: Image(systemName: "play.fill")
                ),
                title: "Bookmark",
                isSelected: viewModel.isPlaying
            ) {
                viewModel.togglePlayPause()
            }
            
            
            AppButton(
                style: .icon,
                tone: .brand, size: .compact,
                icon: .only(Image(systemName: "goforward.15")),
                title: "forward",
            ) {
                viewModel.seekForward()
            }
            
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Texto inferior (lyrics / preview)
    private var lyrics: some View {
        VStack(spacing: 4) {
            Text("Why aren't more people investing")
                .font(.system(size: 15))
                .foregroundStyle(.gray.opacity(0.5))
            
            Text("in Africa's green energy?")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black)
            
            Text("Environmental researcher")
                .font(.system(size: 14))
                .foregroundStyle(.gray.opacity(0.6))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}

#Preview {
    PlayerView(episode: .mock)
}
