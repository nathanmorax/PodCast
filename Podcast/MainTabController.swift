//
//  MainTabController.swift
//  Podcast
//
//  Created by Nathan Mora on 07/11/23.
//

import SwiftUI
import UIKit

struct UIViewControllerHost: UIViewControllerRepresentable {
    let builder: () -> UIViewController
    
    func makeUIViewController(context: Context) -> UIViewController {
        builder()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}


struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Search", systemImage: "magnifyingglass") {
                UIViewControllerHost {
                    UINavigationController(rootViewController: PodcastSearchContainerController())
                }
            }
            
            Tab("Favorites", systemImage: "heart") {
                UIViewControllerHost {
                    UINavigationController(rootViewController: FavoritesPodcastController())
                }
            }
            
            Tab("Downloads", systemImage: "arrow.down.circle") {
                UIViewControllerHost {
                    UINavigationController(rootViewController: UIViewController())
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            MiniPlayerView()
        }
    }
}


struct MiniPlayerView: View {
    
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    
    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(uiColor: .systemGray4))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundStyle(.secondary)
                )
            
            if placement == .expanded {
                // Cuando hay espacio (sin scroll), muestra título y autor
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nombre del episodio")
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    Text("Podcast")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 8)
            }
            
            // Botón play/pause (siempre visible)
            Button {
                // PlayerManager.shared.togglePlayPause()
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
    }
}
