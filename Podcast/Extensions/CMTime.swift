//
//  CMTime.swift
//  Podcast
//
//  Created by Nathan Mora on 19/11/23.
//

import AVKit

extension CMTime {
   func toDisplayString() -> String {
      let totalSeconds = Int(CMTimeGetSeconds(self))
      let seconds = totalSeconds % 60
      let minutes = totalSeconds / 60
      let hours = totalSeconds / 60
      let timeFormatString = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
      return timeFormatString
   }
}
