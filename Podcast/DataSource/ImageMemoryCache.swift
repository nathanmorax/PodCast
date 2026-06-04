//
//  ImageMemoryCache.swift
//  Podcast
//
//  Created by Jonathan Mora on 14/05/26.
//
import Foundation
import SwiftUI

/// Cache de imágenes ya decodificadas en memoria.
/// Apple ya tiene URLCache (data en disco), pero decodificar es caro,
/// por eso guardamos UIImage ya lista para mostrar.
final class ImageMemoryCache {
    
    static let shared = ImageMemoryCache()
    private init() {
        cache.totalCostLimit = 50 * 1024 * 1024
        
    }
    
    private let cache = NSCache<NSURL, UIImage>()
    
    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func insert(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

