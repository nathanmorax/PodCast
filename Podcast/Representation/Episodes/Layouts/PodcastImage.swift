//
//  PodcastImage.swift
//  Podcast
//
//  Created by Satori Tech 341 on 11/05/26.
//

import SwiftUI

/// Muestra una imagen desde una URL remota, un asset local, o un placeholder.
/// Detecta automáticamente el tipo de fuente según el string que recibe.
struct PodcastImage: View {
    
    let source: String?
    var contentMode: ContentMode = .fill
    var placeholder: Color = Color(uiColor: .secondarySystemFill)
    
    var body: some View {
        if let source, !source.isEmpty {
            if source.hasPrefix("http"), let url = URL(string: source) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } placeholder: {
                    placeholder
                }
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
