//
//  UIImage+ArtworkTint.swift
//  Podcast
//

import UIKit

extension UIImage {

    /// The artwork's background color: its edges when they're one color
    /// (most covers: a name over a flat background), otherwise the average
    /// of the whole image. Reads a 24×24 copy, so it's cheap; still, call it
    /// off the main actor (ArtworkTintLoader does).
    func artworkTint() -> ArtworkTint? {
        guard let cgImage else { return nil }

        let side = 24
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        guard let context = CGContext(
            data: &pixels,
            width: side, height: side,
            bitsPerComponent: 8,
            bytesPerRow: side * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))

        var edge: [SIMD3<Double>] = []
        var total = SIMD3<Double>(repeating: 0)
        let ring = 2
        for y in 0..<side {
            for x in 0..<side {
                let offset = (y * side + x) * 4
                let pixel = SIMD3<Double>(
                    Double(pixels[offset]) / 255,
                    Double(pixels[offset + 1]) / 255,
                    Double(pixels[offset + 2]) / 255
                )
                total += pixel
                if x < ring || y < ring || x >= side - ring || y >= side - ring {
                    edge.append(pixel)
                }
            }
        }

        let edgeMean = edge.reduce(SIMD3<Double>(repeating: 0), +) / Double(edge.count)
        // How far the edge pixels stray from their mean: small = flat background.
        let spread = edge
            .map { pixel -> Double in
                let d = pixel - edgeMean
                return (d * d).sum().squareRoot()
            }
            .reduce(0, +) / Double(edge.count)

        let picked = spread < 0.14 ? edgeMean : total / Double(side * side)
        return ArtworkTint(red: picked.x, green: picked.y, blue: picked.z).softened()
    }
}
