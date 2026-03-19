//
//  FavoritesPodcastCell.swift
//  Podcast
//
//  Created by Satori Tech 341 on 19/03/26.
//
import UIKit

class FavoritesPodcastCell: UICollectionViewCell {
    
    static let favoritesPodcastCellId = "FavoritesPodcastCellId"
    
    let imageView = UIImageView(image: UIImage(named: "appicon"))

    let titlePodcastLabel = UILabel()
    let artistNameLabel = UILabel()
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        
        titlePodcastLabel.text = "Title Podcast"
        titlePodcastLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        artistNameLabel.text = "Artist Name"
        artistNameLabel.font = UIFont.systemFont(ofSize: 14)
        artistNameLabel.textColor = .lightGray
        
        let stackView = UIStackView(arrangedSubviews: [
            imageView ,titlePodcastLabel, artistNameLabel
        ])
        
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
    }
}
