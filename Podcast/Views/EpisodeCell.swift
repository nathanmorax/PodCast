//
//  EpisodeCell.swift
//  Podcast
//
//  Created by Xcaret Mora on 16/11/23.
//

import UIKit
import Alamofire

class EpisodeCell: UITableViewCell {

    @IBOutlet weak var imageEpisodeView: UIImageView!
    @IBOutlet weak var pubDateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var episode: Episode? {
        didSet {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            pubDateLabel.text = dateFormatter.string(from: episode?.pubDate ?? Date())
            titleLabel.text = episode?.title
            descriptionLabel.text = episode?.description
            imageEpisodeView.sd_setImage(with: URL(string: episode?.imageUrl?.toSecureHTTPS() ?? ""), completed: nil)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
