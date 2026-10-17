//
//  UIImage+Decode.swift
//  Podcast
//
//  Created by Jonathan Mora on 14/05/26.
//
import SwiftUI

extension UIImage {
    
    /// Decodes the image off the main actor so scrolling never waits for it.
    ///
    /// `@concurrent` states it explicitly (and keeps it true if the project
    /// turns on Approachable Concurrency, where plain `async` functions would
    /// run on the caller's actor). Before, an extra unstructured `Task` did the
    /// hop: it also lost cancellation when the image's view went away.
    @concurrent
    static func decode(from data: Data) async -> UIImage? {
        guard !Task.isCancelled else { return nil }
        return UIImage(data: data)?.preparingForDisplay()
    }
}
