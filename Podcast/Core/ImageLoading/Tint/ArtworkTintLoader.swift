//
//  ArtworkTintLoader.swift
//  Podcast
//

import UIKit

/// Gets the tint of a podcast's artwork. Uses the same image the list just
/// showed (ImageMemoryCache), so opening a podcast from a cell paints its
/// page right away; downloads it otherwise. Remembers each tint.
@MainActor
enum ArtworkTintLoader {

    private static var tints: [String: ArtworkTint] = [:]

    /// Already computed: the page can start painted, with no fade.
    static func cachedTint(for source: String?) -> ArtworkTint? {
        guard let source else { return nil }
        return tints[source]
    }

    static func tint(for source: String?) async -> ArtworkTint? {
        guard let source, !source.isEmpty else { return nil }
        if let known = tints[source] { return known }
        guard let image = await image(for: source) else { return nil }

        let tint = await Task.detached(priority: .userInitiated) {
            image.artworkTint()
        }.value
        if let tint { tints[source] = tint }
        return tint
    }

    /// A remote URL (the cells' 600 px artwork) or an asset name (previews).
    private static func image(for source: String) async -> UIImage? {
        guard source.hasPrefix("http"), let url = URL(string: source) else {
            return UIImage(named: source)
        }
        if let cached = ImageMemoryCache.shared.image(for: url) { return cached }

        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 30)
        guard let data = try? await URLSession.shared.data(for: request).0,
              let decoded = await UIImage.decode(from: data) else { return nil }
        ImageMemoryCache.shared.insert(decoded, for: url)
        return decoded
    }
}
