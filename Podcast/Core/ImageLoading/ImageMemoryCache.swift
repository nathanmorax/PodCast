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
///
/// `@unchecked Sendable` — safety invariant: the only stored state is an
/// immutable `let` to an NSCache, which Apple documents as thread-safe, and
/// `totalCostLimit` is set once in `init`. Remove the `@unchecked` if NSCache
/// is ever annotated Sendable by the SDK, or if mutable state is added
/// (then it should become an actor or use Mutex).
final class ImageMemoryCache: @unchecked Sendable {
    
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

