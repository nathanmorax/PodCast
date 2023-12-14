//
//  PodcastCell.swift
//  Podcast
//
//  Created by Nathan Mora on 16/11/23.
//

import UIKit
import SDWebImage

class PodcastCell: UITableViewCell {
   
   @IBOutlet weak var podcastImageView: UIImageView!
   @IBOutlet weak var trackNameLabel: UILabel!
   @IBOutlet weak var artistNameLabel: UILabel!
   @IBOutlet weak var episodeCountLabel: UILabel!
   
   var podcast: Podcast? {
      didSet {
         trackNameLabel.text = podcast?.trackName
         artistNameLabel.text = podcast?.artistName
         episodeCountLabel.text = "\(podcast?.trackCount ?? 0) Episodes"
         podcastImageView.sd_setImage(with: URL(string: podcast?.artworkUrl600 ?? ""), completed: nil)
         
      }
   }
}
