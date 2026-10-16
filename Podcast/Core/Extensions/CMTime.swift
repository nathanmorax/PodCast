//
//  CMTime.swift
//  Podcast
//
//  Created by Nathan Mora on 19/11/23.
//

import AVKit

extension CMTime {
    func toDisplayString() -> String {
        guard self.isValid, !self.isIndefinite, self.seconds.isFinite else {
            return "00:00:00"
        }
        
        let totalSeconds = Int(self.seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
