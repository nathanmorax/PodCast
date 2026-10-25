//
//  PodcastImage.swift
//  Podcast
//
//  Created by Jonathan Mora on 11/05/26.
//
import SwiftUI
import UIKit

/// Muestra una imagen desde una URL remota, un asset local, o un placeholder.
/// Detecta automáticamente el tipo de fuente según el string que recibe.
struct PodcastImage: View {
    
    let source: String?
    var contentMode: ContentMode = .fill
    var placeholder: Color = Color(uiColor: .secondarySystemFill)
    
    var body: some View {
        if let source, !source.isEmpty {
            if source.hasPrefix("http"), let url = URL(string: source) {
                RemotePodcastImage(
                    url: url,
                    contentMode: contentMode,
                    placeholder: placeholder
                )
            } else {
                Image(source)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
        } else {
            placeholder
        }
    }
}

// MARK: - Imagen remota con cache

private struct RemotePodcastImage: View {
    
    let url: URL
    let contentMode: ContentMode
    let placeholder: Color
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else {
                placeholder
            }
        }
        // `.task(id:)` instead of onAppear/onDisappear: it re-runs whenever the URL
        // changes while the view stays on screen (mini player switching episodes,
        // reused cells) and cancels the previous load automatically.
        // onAppear only fired once, so the old artwork stayed until the view was
        // recreated (e.g. opening the full player).
        .task(id: url) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        if let cached = ImageMemoryCache.shared.image(for: url) {
            image = cached
            return
        }
        
        // Don't keep showing the previous URL's artwork while the new one loads.
        image = nil
        
        do {
            let request = URLRequest(
                url: url,
                cachePolicy: .returnCacheDataElseLoad,
                timeoutInterval: 30
            )
            
            let (data, _) = try await URLSession.shared.data(for: request)
            guard !Task.isCancelled else { return }
            
            guard let decoded = await UIImage.decode(from: data),
                  !Task.isCancelled else { return }
            
            ImageMemoryCache.shared.insert(decoded, for: url)
            
            withAnimation(AppAnimation.imageAppear) {
                image = decoded
            }
        } catch {
            // Cancelled (URL changed / view left the screen) or network error.
        }
    }
}
