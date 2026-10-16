//
//  MiniPlayerView.swift
//  Podcast
//
//  Created by Jonathan Mora on 12/05/26.
//
import SwiftUI

struct MiniPlayerView: View {
    
    let episode: Episode
    let viewModel: AVPlayerViewModel
    var onExpand: () -> Void = {}
    
    // Lives inside the tab bar's bottom accessory: the system draws the glass
    // capsule and sets the height (~48pt), so no own background and compact controls.
    var body: some View {
        HStack(spacing: 4) {
            
            // Only the info area expands the player; play/forward are separate buttons.
            Button(action: onExpand) {
                HStack(spacing: 10) {
                    PodcastImage(source: episode.imageUrl)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(episode.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                        
                        Text(episode.author)
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Abre el reproductor")
            
            Button {
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel(viewModel.isPlaying ? "Pausar" : "Reproducir")
            
            Button {
                viewModel.seekForward()
            } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Adelantar 15 segundos")
        }
        .foregroundStyle(.black)
        .padding(.leading, 10)
        .padding(.trailing, 6)
        // Fill the accessory's height so the row is vertically centered in the capsule.
        .frame(maxHeight: .infinity)
    }
}

//#Preview {
//    MiniPlayerView(episode: Episode.mock, viewModel: AVPlayerViewModel())
//}


struct HeaderEpisodeView: View {
    
    let episode: Episode
    
    var body: some View {
        HStack(spacing: 12) {
            
            PodcastImage(source: episode.imageUrl)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(.black)
                
                Text(episode.author)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }
            
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        )
    }
}


//#Preview {
//    HeaderEpisodeView(episode: Episode.mock)
//}
