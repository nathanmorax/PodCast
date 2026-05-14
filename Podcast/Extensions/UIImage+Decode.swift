//
//  UIImage+Decode.swift
//  Podcast
//
//  Created by Jonathan Mora on 14/05/26.
//
import SwiftUI

extension UIImage {
    
    /// Decodifica la imagen en background para no bloquear el main thread.
    static func decode(from data: Data) async -> UIImage? {
        await Task(priority: .userInitiated) {
            UIImage(data: data)?.preparingForDisplay()
        }.value
    }
}
