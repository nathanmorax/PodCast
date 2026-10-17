//
//  PlayerDataSource.swift
//  Podcast
//

import UIKit
import AVFoundation

/// Class-bound so AVPlayerViewModel can set its callbacks; tests use a fake.
/// @MainActor: AVPlayer's state drives the UI and its time observer is
/// delivered on the main queue.
@MainActor
protocol PlayerDataSource: AnyObject {
    
    var onTimeUpdate: ((CMTime, CMTime?) -> Void)? { get set }
    var onStateChange: ((Bool) -> Void)? { get set }
    var onEpisodeStarted: (() -> Void)? { get set }
    
    
    func play(url: URL)
    func resume()
    func pause()
    func seek(by seconds: Int64)
    func seek(to percentage: Float)
    func setVolume(_ value: Float)
}
