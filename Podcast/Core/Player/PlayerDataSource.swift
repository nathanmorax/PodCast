//
//  PlayerDataSource.swift
//  Podcast
//

import UIKit
import AVFoundation

/// Class-bound so AVPlayerViewModel can set its callbacks; tests use a fake.
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
