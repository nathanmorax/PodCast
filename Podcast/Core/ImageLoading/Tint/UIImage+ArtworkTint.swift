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

        // Plain Doubles, no SIMD: `reduce(_, +)` over SIMD types has many
        // overloads to pick from and was slow to type-check.
        var edge: [(r: Double, g: Double, b: Double)] = []
        var totalR = 0.0, totalG = 0.0, totalB = 0.0
        let ring = 2
        for y in 0..<side {
            for x in 0..<side {
                let offset = (y * side + x) * 4
                let r = Double(pixels[offset]) / 255
                let g = Double(pixels[offset + 1]) / 255
                let b = Double(pixels[offset + 2]) / 255
                totalR += r
                totalG += g
                totalB += b
                if x < ring || y < ring || x >= side - ring || y >= side - ring {
                    edge.append((r, g, b))
                }
            }
        }

        let edgeCount = Double(edge.count)
        var edgeR = 0.0, edgeG = 0.0, edgeB = 0.0
        for pixel in edge {
            edgeR += pixel.r
            edgeG += pixel.g
            edgeB += pixel.b
        }
        edgeR /= edgeCount
        edgeG /= edgeCount
        edgeB /= edgeCount

        // How far the edge pixels stray from their mean: small = flat background.
        var spread = 0.0
        for pixel in edge {
            let dr: Double = pixel.r - edgeR
            let dg: Double = pixel.g - edgeG
            let db: Double = pixel.b - edgeB
            spread += (dr * dr + dg * dg + db * db).squareRoot()
        }
        spread /= edgeCount

        let pixelCount = Double(side * side)
        if spread < 0.14 {
            return ArtworkTint(red: edgeR, green: edgeG, blue: edgeB).softened()
        }
        return ArtworkTint(red: totalR / pixelCount, green: totalG / pixelCount, blue: totalB / pixelCount).softened()
    }
}
