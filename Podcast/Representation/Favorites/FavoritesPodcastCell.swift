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
        self.configure()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        
        let stackView = UIStackView(arrangedSubviews: [
            imageView ,titlePodcastLabel, artistNameLabel
        ])
        
        titlePodcastLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        artistNameLabel.font = UIFont.systemFont(ofSize: 14)
        artistNameLabel.textColor = .lightGray
        
        imageView.cornerRadius
        
        contentView.backgroundColor = .clear
        
        stackView.axis = .vertical
        stackView.backgroundColor = .clear
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configureData(with podcast: Podcast) {
        
        titlePodcastLabel.text = podcast.trackName
        
        artistNameLabel.text = podcast.artistName
        
        imageView.sd_setImage(with: URL(string: podcast.artworkUrl600 ?? ""), completed: nil)

    }
}
