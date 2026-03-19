//
//  File.swift
//  Podcast
//
//  Created by Nathan Mora on 19/03/26.
//
import UIKit

extension UIImage {
    func averageBrightness() -> CGFloat {
        guard let cgImage = self.cgImage else { return 0.5 }

        let width  = 40
        let height = 40
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width, height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 0.5 }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var totalBrightness: CGFloat = 0
        let pixelCount = width * height

        for i in 0..<pixelCount {
            let offset = i * 4
            let r = CGFloat(pixels[offset])     / 255
            let g = CGFloat(pixels[offset + 1]) / 255
            let b = CGFloat(pixels[offset + 2]) / 255
            totalBrightness += 0.299 * r + 0.587 * g + 0.114 * b
        }

        return totalBrightness / CGFloat(pixelCount)
    }
}

extension UIView {
    
    var cornerRadius: Void {
        layer.cornerRadius = 8
        clipsToBounds = true
    }
}
